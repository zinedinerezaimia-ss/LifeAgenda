import Foundation
import WidgetKit

// ═══════════════════════════════════════════════════════════════
// SERVICE — Sync données vers Widget & App Group Iqra
// ═══════════════════════════════════════════════════════════════

extension AppStore {
    
    /// Écrit les données du jour dans le App Group pour que
    /// le widget et Iqra puissent les lire
    func syncToWidget() {
        let today = Date()
        let tasks = tasksForDate(today)
        let dateStr = Self.format(today)
        let comps = completions[dateStr] ?? [:]
        
        // Format Widget Tasks
        let widgetTasks = tasks.prefix(8).map { task in
            WidgetTaskData(
                id: task.id,
                name: task.name,
                time: task.time,
                colorHex: task.color.hexString,
                completed: comps[task.id]
            )
        }
        
        if let encoded = try? JSONEncoder().encode(Array(widgetTasks)) {
            Self.userDefaults.set(encoded, forKey: "widgetTasks")
        }
        
        // Shared data pour Iqra
        let shared = SharedAgendaData(
            dailyStreak: streak(),
            todayProgress: progressForDate(today),
            lastUpdated: Date(),
            completedToday: comps.compactMap { $0.value ? $0.key : nil }
        )
        if let encoded = try? JSONEncoder().encode(shared) {
            Self.userDefaults.set(encoded, forKey: "lifeagenda_shared")
        }
        
        WidgetCenter.shared.reloadAllTimelines()
    }
}

struct WidgetTaskData: Codable {
    let id: String
    let name: String
    let time: String
    let colorHex: String
    let completed: Bool?
}

extension TaskColor {
    var hexString: String {
        switch self {
        case .gold:   return "#d4a853"
        case .green:  return "#2dd4bf"
        case .blue:   return "#3b82f6"
        case .purple: return "#a855f7"
        case .red:    return "#ef4444"
        }
    }
}
