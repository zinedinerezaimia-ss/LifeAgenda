import SwiftUI

struct AdhanSettingsView: View {
    @EnvironmentObject var store: AppStore
    @StateObject private var adhan = AdhanService.shared

    let prayers = ["Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"]
    let prayerEmojis = ["🌙", "☀️", "🌤️", "🌅", "🌑"]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {

            // Header
            HStack {
                Image(systemName: "speaker.wave.3.fill")
                    .foregroundColor(.green)
                    .font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Adhan (Appel à la prière)")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Le son d'adhan joue aux heures de prière")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()
            }

            // Toggle global
            HStack {
                Text("Activer l'adhan")
                    .foregroundColor(.white)
                Spacer()
                Toggle("", isOn: $adhan.adhanEnabled)
                    .tint(.green)
                    .onChange(of: adhan.adhanEnabled) { _, _ in
                        adhan.savePreferences()
                        if adhan.adhanEnabled {
                            Task { await adhan.downloadAdhanIfNeeded() }
                            rescheduleAdhan()
                        } else {
                            adhan.cancelAllAdhan()
                        }
                    }
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)

            if adhan.adhanEnabled {

                // Statut téléchargement
                if adhan.isDownloading {
                    HStack {
                        ProgressView()
                            .tint(.green)
                        Text("Téléchargement de l'adhan en cours...")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)
                } else if adhan.isDownloaded {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Adhan téléchargé et prêt")
                            .font(.caption)
                            .foregroundColor(.green)

                        Spacer()

                        // Bouton test
                        Button(action: { adhan.playAdhan() }) {
                            Label("Tester", systemImage: "play.fill")
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.green.opacity(0.2))
                                .cornerRadius(8)
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.horizontal)
                } else {
                    Button(action: {
                        Task { await adhan.downloadAdhanIfNeeded() }
                    }) {
                        Label("Télécharger l'adhan", systemImage: "arrow.down.circle.fill")
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(8)
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal)
                }

                // Par prière
                VStack(spacing: 1) {
                    ForEach(Array(prayers.enumerated()), id: \.offset) { index, prayer in
                        HStack {
                            Text(prayerEmojis[index])
                            Text(prayer)
                                .foregroundColor(.white)

                            // Heure actuelle
                            if let time = store.prayerTimes[prayer] {
                                Text(time)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }

                            Spacer()

                            Toggle("", isOn: Binding(
                                get: { adhan.adhanPerPrayer[prayer] ?? true },
                                set: { val in
                                    adhan.adhanPerPrayer[prayer] = val
                                    adhan.savePreferences()
                                    rescheduleAdhan()
                                }
                            ))
                            .tint(.green)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.04))
                    }
                }
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08)))
            }
        }
        .onAppear {
            if adhan.adhanEnabled && !adhan.isDownloaded {
                Task { await adhan.downloadAdhanIfNeeded() }
            }
        }
    }

    private func rescheduleAdhan() {
        adhan.scheduleAllAdhan(prayerTimes: store.prayerTimes)
    }
}
