import WidgetKit
import SwiftUI

// ═══════════════════════════════════════════════════════════════
// WIDGET — LifeAgenda
// Affiche les tâches du jour avec progression
// ═══════════════════════════════════════════════════════════════

// MARK: — Shared data loader

struct WidgetDataProvider {
    static let appGroupID = "group.com.rezaimia.shared"
    static let userDefaults = UserDefaults(suiteName: appGroupID)
    
    static func loadTodayTasks() -> [WidgetTask] {
        guard let ud = userDefaults,
              let data = ud.data(forKey: "widgetTasks"),
              let tasks = try? JSONDecoder().decode([WidgetTask].self, from: data)
        else { return [] }
        return tasks
    }
    
    static func loadSharedData() -> WidgetSharedData {
        guard let ud = userDefaults,
              let data = ud.data(forKey: "lifeagenda_shared"),
              let shared = try? JSONDecoder().decode(WidgetSharedData.self, from: data)
        else { return .empty }
        return shared
    }
}

struct WidgetTask: Codable, Identifiable {
    let id: String
    let name: String
    let time: String
    let colorHex: String
    let completed: Bool?
}

struct WidgetSharedData: Codable {
    let dailyStreak: Int
    let todayProgress: Double
    let lastUpdated: Date
    let completedToday: [String]
    
    static var empty: WidgetSharedData {
        WidgetSharedData(dailyStreak: 0, todayProgress: 0, lastUpdated: Date(), completedToday: [])
    }
}

// MARK: — Timeline Entry

struct AgendaEntry: TimelineEntry {
    let date: Date
    let tasks: [WidgetTask]
    let shared: WidgetSharedData
}

// MARK: — Provider

struct AgendaProvider: TimelineProvider {
    func placeholder(in context: Context) -> AgendaEntry {
        AgendaEntry(date: Date(), tasks: sampleTasks, shared: .empty)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (AgendaEntry) -> Void) {
        completion(AgendaEntry(date: Date(), tasks: WidgetDataProvider.loadTodayTasks(), shared: WidgetDataProvider.loadSharedData()))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<AgendaEntry>) -> Void) {
        let entry = AgendaEntry(date: Date(), tasks: WidgetDataProvider.loadTodayTasks(), shared: WidgetDataProvider.loadSharedData())
        // Refresh toutes les 30 minutes
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
    
    private var sampleTasks: [WidgetTask] {
        [
            WidgetTask(id: "1", name: "Fajr 🌅",        time: "05:30", colorHex: "#d4a853", completed: true),
            WidgetTask(id: "2", name: "Sport Matin 💪",  time: "07:40", colorHex: "#2dd4bf", completed: nil),
            WidgetTask(id: "3", name: "Dhuhr ☀️",        time: "13:04", colorHex: "#d4a853", completed: nil),
            WidgetTask(id: "4", name: "Coran 📖",        time: "18:30", colorHex: "#a855f7", completed: nil),
        ]
    }
}

// MARK: — Widget Views

@main
struct LifeAgendaWidget: WidgetBundle {
    var body: some Widget {
        HomeScreenWidget()
        LockScreenWidget()
    }
}

// Home Screen Widget
struct HomeScreenWidget: Widget {
    let kind = "LifeAgendaHomeWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AgendaProvider()) { entry in
            HomeScreenWidgetView(entry: entry)
        }
        .configurationDisplayName("LifeAgenda")
        .description("Vos tâches du jour en un coup d'œil.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct HomeScreenWidgetView: View {
    let entry: AgendaEntry
    @Environment(\.widgetFamily) var family
    
    var visibleTasks: [WidgetTask] {
        switch family {
        case .systemSmall:  return Array(entry.tasks.prefix(3))
        case .systemMedium: return Array(entry.tasks.prefix(4))
        default:            return Array(entry.tasks.prefix(8))
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text("LifeAgenda")
                        .font(.system(size: family == .systemSmall ? 11 : 13, weight: .bold))
                        .foregroundColor(Color(hex: "#d4a853"))
                    if family != .systemSmall {
                        Text(Date().formatted(.dateTime.weekday(.abbreviated).day().month()))
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                    }
                }
                Spacer()
                
                // Progress ring
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 2.5)
                    Circle()
                        .trim(from: 0, to: entry.shared.todayProgress)
                        .stroke(Color(hex: "#d4a853"), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text("\(Int(entry.shared.todayProgress * 100))%")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Color(hex: "#d4a853"))
                }
                .frame(width: family == .systemSmall ? 32 : 38, height: family == .systemSmall ? 32 : 38)
            }
            
            // Tasks
            ForEach(visibleTasks) { task in
                WidgetTaskRow(task: task, compact: family == .systemSmall)
            }
            
            Spacer(minLength: 0)
            
            // Streak
            if family != .systemSmall {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Color(hex: "#d4a853"))
                    Text("\(entry.shared.dailyStreak) jours")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(12)
        .background(Color(hex: "#0a0a0a"))
    }
}

struct WidgetTaskRow: View {
    let task: WidgetTask
    let compact: Bool
    
    private var statusColor: Color {
        if task.completed == true  { return .green }
        if task.completed == false { return .red }
        return Color(hex: task.colorHex)
    }
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)
            
            if !compact {
                Text(task.time)
                    .font(.system(size: 10).monospaced())
                    .foregroundColor(.gray)
                    .frame(width: 36)
            }
            
            Text(task.name)
                .font(.system(size: compact ? 11 : 12, weight: .medium))
                .foregroundColor(task.completed == true ? .gray : .white)
                .strikethrough(task.completed == true)
                .lineLimit(1)
            
            Spacer()
            
            if task.completed == true {
                Image(systemName: "checkmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.green)
            }
        }
    }
}

// Lock Screen Widget
struct LockScreenWidget: Widget {
    let kind = "LifeAgendaLockWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AgendaProvider()) { entry in
            LockScreenWidgetView(entry: entry)
        }
        .configurationDisplayName("LifeAgenda Progression")
        .description("Progression du jour sur l'écran de verrouillage.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

struct LockScreenWidgetView: View {
    let entry: AgendaEntry
    @Environment(\.widgetFamily) var family
    
    var completedCount: Int { entry.tasks.filter { $0.completed == true }.count }
    var totalCount: Int { max(entry.tasks.count, 1) }
    
    var body: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                Gauge(value: entry.shared.todayProgress) {
                    Text("✓")
                        .font(.system(size: 10, weight: .bold))
                }
                .gaugeStyle(.accessoryCircular)
            }
        case .accessoryRectangular:
            HStack(spacing: 8) {
                Image(systemName: "flame.fill")
                VStack(alignment: .leading, spacing: 1) {
                    Text("\(completedCount)/\(totalCount) tâches")
                        .font(.system(size: 13, weight: .semibold))
                    Text("\(entry.shared.dailyStreak) jours de streak 🔥")
                        .font(.system(size: 11))
                }
            }
        default:
            Text("\(completedCount)/\(totalCount) LifeAgenda")
        }
    }
}

// MARK: — Color helper for Widget

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
