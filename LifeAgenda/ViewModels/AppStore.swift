import Foundation
import SwiftUI
import WidgetKit

// ═══════════════════════════════════════════════════════════════
// APP STORE — Source de vérité unique
// ═══════════════════════════════════════════════════════════════

class AppStore: ObservableObject {
    // App Group pour partage avec Iqra
    static let appGroupID = "group.com.rezaimia.shared"
    static let userDefaults = UserDefaults(suiteName: appGroupID) ?? .standard
    
    // MARK: — État publié
    @Published var customTasks:  [DateString: [DailyTask]]         = [:]
    @Published var completions:  [DateString: [TaskID: Bool]]      = [:]
    @Published var activePunishments: [DateString: [String]]       = [:]
    @Published var ideas:        [IdeaItem]                        = []
    @Published var transactions: [Transaction]                     = []
    @Published var budget:       Double                            = 0
    
    // MARK: — Init
    init() {
        load()
    }
    
    // MARK: — Agenda
    
    func tasksForDate(_ date: Date) -> [DailyTask] {
        let dateStr = Self.format(date)
        let fixed = DailyTask.fixedAxes
        let custom = customTasks[dateStr] ?? []
        return (fixed + custom).sorted { $0.timeInMinutes < $1.timeInMinutes }
    }
    
    func isCompleted(_ taskID: TaskID, date: Date) -> Bool? {
        completions[Self.format(date)]?[taskID]
    }
    
    func validate(task: DailyTask, completed: Bool, date: Date) {
        let key = Self.format(date)
        if completions[key] == nil { completions[key] = [:] }
        completions[key]![task.id] = completed
        saveCompletions()
        updateSharedData(for: date)
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    func addTask(_ task: DailyTask, date: Date) {
        let key = Self.format(date)
        if customTasks[key] == nil { customTasks[key] = [] }
        customTasks[key]!.append(task)
        saveCustomTasks()
    }
    
    func deleteTask(id: TaskID, date: Date) {
        let key = Self.format(date)
        customTasks[key]?.removeAll { $0.id == id }
        completions[key]?.removeValue(forKey: id)
        saveCustomTasks()
        saveCompletions()
    }
    
    func addPunishment(_ punishment: Punishment, date: Date) {
        let key = Self.format(date)
        if activePunishments[key] == nil { activePunishments[key] = [] }
        if !activePunishments[key]!.contains(punishment.id) {
            activePunishments[key]!.append(punishment.id)
        }
        savePunishments()
    }
    
    func punishmentsForDate(_ date: Date) -> [Punishment] {
        let ids = activePunishments[Self.format(date)] ?? []
        return Punishment.defaults.filter { ids.contains($0.id) }
    }
    
    func progressForDate(_ date: Date) -> Double {
        let key = Self.format(date)
        let comps = completions[key] ?? [:]
        let total = DailyTask.fixedAxes.count
        let done  = comps.values.filter { $0 }.count
        return total > 0 ? Double(done) / Double(total) : 0
    }
    
    func streak() -> Int {
        var count = 0
        var date = Calendar.current.startOfDay(for: Date())
        for _ in 0..<365 {
            let p = progressForDate(date)
            if p >= 0.8 { count += 1 } else { break }
            date = Calendar.current.date(byAdding: .day, value: -1, to: date)!
        }
        return count
    }
    
    // MARK: — Ideas
    
    func addIdea(_ idea: IdeaItem) {
        ideas.insert(idea, at: 0)
        saveIdeas()
    }
    
    func deleteIdea(id: String) {
        ideas.removeAll { $0.id == id }
        saveIdeas()
    }
    
    // MARK: — Money
    
    func addTransaction(_ tx: Transaction) {
        transactions.insert(tx, at: 0)
        saveTransactions()
    }
    
    func deleteTransaction(id: String) {
        transactions.removeAll { $0.id == id }
        saveTransactions()
    }
    
    var balance: Double {
        budget + transactions.reduce(0) { $0 + $1.amount }
    }
    
    // MARK: — Shared Data (App Group → Iqra)
    
    private func updateSharedData(for date: Date) {
        let data = SharedAgendaData(
            dailyStreak: streak(),
            todayProgress: progressForDate(Date()),
            lastUpdated: Date(),
            completedToday: completions[Self.format(Date())]?.compactMap { $0.value ? $0.key : nil } ?? []
        )
        if let encoded = try? JSONEncoder().encode(data) {
            Self.userDefaults.set(encoded, forKey: "lifeagenda_shared")
        }
    }
    
    // MARK: — Persistance
    
    static func format(_ date: Date) -> DateString {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
    
    private func load() {
        customTasks        = decode([DateString: [DailyTask]].self,       key: "customTasks")  ?? [:]
        completions        = decode([DateString: [TaskID: Bool]].self,    key: "completions")  ?? [:]
        activePunishments  = decode([DateString: [String]].self,          key: "punishments")  ?? [:]
        ideas              = decode([IdeaItem].self,                      key: "ideas")        ?? []
        transactions       = decode([Transaction].self,                   key: "transactions") ?? []
        budget             = UserDefaults.standard.double(forKey: "budget")
    }
    
    private func decode<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
    
    private func encode<T: Encodable>(_ value: T, key: String) {
        if let data = try? JSONEncoder().encode(value) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    
    func saveCompletions()   { encode(completions,       key: "completions") }
    func saveCustomTasks()   { encode(customTasks,       key: "customTasks") }
    func savePunishments()   { encode(activePunishments, key: "punishments") }
    func saveIdeas()         { encode(ideas,             key: "ideas") }
    func saveTransactions()  { encode(transactions,      key: "transactions") }
}

// MARK: — Modèles Ideas & Money

struct IdeaItem: Identifiable, Codable {
    var id: String = UUID().uuidString
    var text: String
    var category: String
    var date: Date = Date()
    var isPinned: Bool = false
}

struct Transaction: Identifiable, Codable {
    var id: String = UUID().uuidString
    var label: String
    var amount: Double
    var category: String
    var date: Date = Date()
    
    var isExpense: Bool { amount < 0 }
}
