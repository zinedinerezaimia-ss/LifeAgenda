import Foundation
import AVFoundation
import UserNotifications

@MainActor
final class AdhanService: ObservableObject {
    static let shared = AdhanService()

    // URL d'un adhan gratuit (Adhan Madinah - domaine public)
    private let adhanURL = "https://www.islamcan.com/audio/adhan/azan1.mp3"
    private let adhanFileName = "adhan.mp3"

    @Published var isDownloaded: Bool = false
    @Published var isDownloading: Bool = false
    @Published var adhanEnabled: Bool = true
    @Published var adhanPerPrayer: [String: Bool] = [
        "Fajr": true,
        "Dhuhr": true,
        "Asr": true,
        "Maghrib": true,
        "Isha": true
    ]

    private var player: AVAudioPlayer?

    private init() {
        isDownloaded = FileManager.default.fileExists(atPath: localAdhanPath.path)
        adhanEnabled = UserDefaults.standard.bool(forKey: "adhan_enabled_pref") == false
            ? true
            : UserDefaults.standard.bool(forKey: "adhan_enabled_pref")

        // Charge les préférences par prière
        for prayer in adhanPerPrayer.keys {
            let key = "adhan_\(prayer)_enabled"
            if UserDefaults.standard.object(forKey: key) != nil {
                adhanPerPrayer[prayer] = UserDefaults.standard.bool(forKey: key)
            }
        }
    }

    // MARK: - Chemin local
    var localAdhanPath: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(adhanFileName)
    }

    // MARK: - Téléchargement
    func downloadAdhanIfNeeded() async {
        guard !isDownloaded && !isDownloading else { return }
        isDownloading = true

        guard let url = URL(string: adhanURL) else {
            isDownloading = false
            return
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                isDownloading = false
                return
            }

            try data.write(to: localAdhanPath)
            isDownloaded = true
            isDownloading = false
            print("✅ Adhan téléchargé: \(localAdhanPath.path)")
        } catch {
            isDownloading = false
            print("❌ Erreur téléchargement adhan: \(error)")
        }
    }

    // MARK: - Lecture directe (quand app est ouverte)
    func playAdhan() {
        guard isDownloaded else {
            Task { await downloadAdhanIfNeeded() }
            return
        }

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            player = try AVAudioPlayer(contentsOf: localAdhanPath)
            player?.prepareToPlay()
            player?.play()
        } catch {
            print("❌ Erreur lecture adhan: \(error)")
        }
    }

    func stopAdhan() {
        player?.stop()
        try? AVAudioSession.sharedInstance().setActive(false)
    }

    // MARK: - Planification notifications avec son adhan
    func schedulePrayerAdhan(prayerName: String, hour: Int, minute: Int) {
        guard adhanEnabled,
              adhanPerPrayer[prayerName] == true else { return }

        let identifier = "adhan_\(prayerName.lowercased())"

        // Supprime l'ancien
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])

        let content = UNMutableNotificationContent()
        content.title = "🕌 \(prayerName)"
        content.body = "C'est l'heure de la prière de \(prayerName)"
        content.interruptionLevel = .timeSensitive

        // Attache le fichier audio si disponible
        if isDownloaded,
           let attachment = try? UNNotificationAttachment(
               identifier: "adhan_audio",
               url: localAdhanPath,
               options: [UNNotificationAttachmentOptionsTypeHintKey: "public.mp3"]
           ) {
            content.attachments = [attachment]
            content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: adhanFileName))
        } else {
            content.sound = .default
        }

        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Erreur notification \(prayerName): \(error)")
            } else {
                print("✅ Adhan planifié pour \(prayerName) à \(hour):\(String(format: "%02d", minute))")
            }
        }
    }

    func scheduleAllAdhan(prayerTimes: [String: String]) {
        for (prayer, time) in prayerTimes {
            let parts = time.split(separator: ":").compactMap { Int($0) }
            guard parts.count == 2 else { continue }
            schedulePrayerAdhan(prayerName: prayer, hour: parts[0], minute: parts[1])
        }
    }

    func cancelAllAdhan() {
        let identifiers = ["adhan_fajr", "adhan_dhuhr", "adhan_asr", "adhan_maghrib", "adhan_isha"]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    // MARK: - Sauvegarde préférences
    func savePreferences() {
        UserDefaults.standard.set(adhanEnabled, forKey: "adhan_enabled_pref")
        for (prayer, enabled) in adhanPerPrayer {
            UserDefaults.standard.set(enabled, forKey: "adhan_\(prayer)_enabled")
        }
    }
}
