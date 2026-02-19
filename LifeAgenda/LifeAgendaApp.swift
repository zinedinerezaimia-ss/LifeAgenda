import SwiftUI

@main
struct LifeAgendaApp: App {
    @StateObject private var store = AppStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
        }
    }
}
