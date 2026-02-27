import SwiftUI

@main
struct LifeAgendaApp: App {
    @StateObject private var store = AppStore()
    @StateObject private var subscriptionService = SubscriptionService.shared
    @StateObject private var locationService = LocationService.shared
    @StateObject private var photoService = PhotoService.shared
    @StateObject private var adhanService = AdhanService.shared

    var body: some Scene {
        WindowGroup {
            Group {
                if store.hasCompletedOnboarding {
                    ContentView()
                } else {
                    OnboardingView()
                }
            }
            .environmentObject(store)
            .environmentObject(subscriptionService)
            .environmentObject(locationService)
            .environmentObject(photoService)
            .environmentObject(adhanService)
            .preferredColorScheme(.dark)
            .onAppear {
                if store.hasCompletedOnboarding {
                    locationService.fetchLocation()
                    store.checkYesterdayPunishments()
                    // Télécharge l'adhan si activé
                    if adhanService.adhanEnabled {
                        Task { await adhanService.downloadAdhanIfNeeded() }
                    }
                }
            }
            .onChange(of: locationService.coordinate) { _, coord in
                if coord != nil {
                    store.refreshPrayerTimes()
                    store.syncToWidget()
                    // Replanifie l'adhan avec les nouvelles heures
                    if adhanService.adhanEnabled {
                        adhanService.scheduleAllAdhan(prayerTimes: store.prayerTimes)
                    }
                }
            }
        }
    }
}
