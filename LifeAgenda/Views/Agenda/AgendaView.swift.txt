import SwiftUI

// ═══════════════════════════════════════════════════════════════
// AGENDA VIEW
// ═══════════════════════════════════════════════════════════════

struct AgendaView: View {
    @EnvironmentObject var store: AppStore
    @State private var currentWeekStart: Date = Date().startOfWeek
    @State private var selectedDate: Date = Date()
    @State private var showAddTask = false
    @State private var punishmentTask: DailyTask? = nil
    
    private var weekDates: [Date] {
        (0..<7).map { Calendar.current.date(byAdding: .day, value: $0, to: currentWeekStart)! }
    }
    
    private var dayTasks: [DailyTask] {
        store.tasksForDate(selectedDate)
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                headerSection
                    .padding(.horizontal, 20)
                    .padding(.top, topSafeArea + 16)
                
                weekSelector
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                
                punishmentsSection
                    .padding(.horizontal, 20)
                
                dateHeader
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                
                timelineSection
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 100)
            }
        }
        .background(AppColors.bgPrimary)
        .sheet(isPresented: $showAddTask) {
            AddTaskSheet(date: selectedDate)
        }
        .sheet(item: $punishmentTask) { task in
            PunishmentSheet(task: task, date: selectedDate)
        }
    }
    
    // MARK: — Header
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("LifeAgenda")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(AppColors.accentGold)
                        .font(.system(size: 13))
                    Text("\(store.streak()) jours de streak")
                        .font(.system(size: 13))
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            Spacer()
            
            // Progress circle
            ZStack {
                Circle()
                    .stroke(AppColors.border, lineWidth: 3)
                    .frame(width: 48, height: 48)
                Circle()
                    .trim(from: 0, to: store.progressForDate(selectedDate))
                    .stroke(AppColors.accentGold, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 48, height: 48)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(), value: store.progressForDate(selectedDate))
                Text("\(Int(store.progressForDate(selectedDate) * 100))%")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(AppColors.accentGold)
            }
        }
    }
    
    // MARK: — Week Selector
    
    private var weekSelector: some View {
        VStack(spacing: 12) {
            // Navigation mois
            HStack {
                Button {
                    withAnimation { currentWeekStart = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: currentWeekStart)! }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)
                        .frame(width: 36, height: 36)
                }
                
                Spacer()
                
                Text(currentWeekStart.formatted(.dateTime.month(.wide).year()))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppColors.textSecondary)
                    .textCase(.uppercase)
                    .kerning(2)
                
                Spacer()
                
                Button {
                    withAnimation { currentWeekStart = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: currentWeekStart)! }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)
                        .frame(width: 36, height: 36)
                }
            }
            
            // Jours
            HStack(spacing: 8) {
                ForEach(Array(weekDates.enumerated()), id: \.offset) { idx, date in
                    DayCell(date: date, isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate), progress: store.progressForDate(date))
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3)) { selectedDate = date }
                        }
                }
            }
        }
    }
    
    // MARK: — Punishments
    
    @ViewBuilder
    private var punishmentsSection: some View {
        let punishments = store.punishmentsForDate(selectedDate)
        if !punishments.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("⚠️ PUNITIONS ACTIVES")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(AppColors.accentRed)
                        .kerning(1)
                    Spacer()
                }
                
                ForEach(punishments) { p in
                    Text(p.name)
                        .font(.system(size: 13))
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .padding(12)
            .background(AppColors.accentRed.opacity(0.1))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.accentRed.opacity(0.4), lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.top, 16)
        }
    }
    
    // MARK: — Date Header
    
    private var dateHeader: some View {
        HStack {
            Text(selectedDate.formatted(.dateTime.weekday(.wide).day()))
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
            Spacer()
            Button {
                showAddTask = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(width: 36, height: 36)
                    .background(AppColors.accentGold)
                    .clipShape(Circle())
            }
        }
    }
    
    // MARK: — Timeline
    
    private var timelineSection: some View {
        ZStack(alignment: .leading) {
            // Ligne verticale
            Rectangle()
                .fill(AppColors.border)
                .frame(width: 1.5)
                .padding(.leading, 56)
                .padding(.vertical, 8)
            
            VStack(spacing: 10) {
                ForEach(dayTasks) { task in
                    TaskRow(task: task, date: selectedDate) { completed in
                        store.validate(task: task, completed: completed, date: selectedDate)
                        if !completed && task.isFixed {
                            punishmentTask = task
                        }
                    }
                }
            }
        }
    }
    
    private var topSafeArea: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.safeAreaInsets.top ?? 44
    }
}

// ═══════════════════════════════════════════════════════════════
// COMPOSANTS
// ═══════════════════════════════════════════════════════════════

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let progress: Double
    
    private var isToday: Bool { Calendar.current.isDateInToday(date) }
    
    private var dayLetters: String {
        date.formatted(.dateTime.weekday(.abbreviated)).prefix(3).uppercased()
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Text(dayLetters)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(isSelected ? .black : AppColors.textMuted)
            
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(isSelected ? .black : AppColors.textPrimary)
            
            // Progress bar
            RoundedRectangle(cornerRadius: 2)
                .fill(isSelected ? Color.black.opacity(0.3) : AppColors.bgSecondary)
                .frame(height: 3)
                .overlay(
                    GeometryReader { geo in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(isSelected ? Color.black : AppColors.accentGreen)
                            .frame(width: geo.size.width * progress)
                    },
                    alignment: .leading
                )
                .animation(.spring(), value: progress)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(isSelected ? AppColors.accentGold : AppColors.bgCard)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isToday && !isSelected ? AppColors.accentGold : .clear, lineWidth: 1.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct TaskRow: View {
    let task: DailyTask
    let date: Date
    let onValidate: (Bool) -> Void
    @EnvironmentObject var store: AppStore
    
    private var completion: Bool? { store.isCompleted(task.id, date: date) }
    private var isCompleted: Bool { completion == true }
    private var isFailed: Bool { completion == false }
    
    private var dotColor: Color {
        if isCompleted { return AppColors.accentGreen }
        if isFailed    { return AppColors.accentRed }
        return task.color.color
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Heure
            Text(task.time)
                .font(.system(size: 11, weight: .regular).monospaced())
                .foregroundColor(AppColors.textMuted)
                .frame(width: 44, alignment: .trailing)
            
            // Dot sur la timeline
            Circle()
                .fill(dotColor)
                .frame(width: 10, height: 10)
                .overlay(Circle().stroke(AppColors.bgPrimary, lineWidth: 3))
                .padding(.horizontal, 10)
            
            // Card
            HStack(spacing: 0) {
                // Barre colorée gauche
                Rectangle()
                    .fill(task.color.color)
                    .frame(width: 3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(task.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(isCompleted ? AppColors.textMuted : task.color.color)
                        .strikethrough(isCompleted)
                    Text("\(task.duration) min")
                        .font(.system(size: 11))
                        .foregroundColor(AppColors.textMuted)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                
                Spacer()
                
                // Boutons validation
                if completion == nil {
                    HStack(spacing: 6) {
                        ActionButton(icon: "checkmark", color: AppColors.accentGreen, tint: .black) {
                            withAnimation(.spring(response: 0.3)) { onValidate(true) }
                        }
                        ActionButton(icon: "xmark", color: AppColors.accentRed, tint: .white) {
                            withAnimation(.spring(response: 0.3)) { onValidate(false) }
                        }
                    }
                    .padding(.trailing, 10)
                } else {
                    Image(systemName: isCompleted ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(isCompleted ? AppColors.accentGreen : AppColors.accentRed)
                        .padding(.trailing, 12)
                }
            }
            .background(task.color.dimColor)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .opacity(isCompleted ? 0.6 : 1)
        }
    }
}

struct ActionButton: View {
    let icon: String
    let color: Color
    let tint: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(tint)
                .frame(width: 30, height: 30)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// FICHE PUNITION
// ═══════════════════════════════════════════════════════════════

struct PunishmentSheet: View {
    let task: DailyTask
    let date: Date
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("😤")
                        .font(.system(size: 60))
                    Text("Tâche manquée")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(AppColors.accentRed)
                    Text("\"\(task.name)\" non complété.\nChoisis ta punition.")
                        .font(.system(size: 15))
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                VStack(spacing: 10) {
                    ForEach(Punishment.defaults) { p in
                        Button {
                            store.addPunishment(p, date: date)
                            dismiss()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(p.name)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(AppColors.textPrimary)
                                    Text(p.description)
                                        .font(.system(size: 12))
                                        .foregroundColor(AppColors.textSecondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(AppColors.textMuted)
                            }
                            .padding(14)
                            .background(AppColors.bgCard)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .background(AppColors.bgPrimary.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") { dismiss() }
                        .foregroundColor(AppColors.accentGold)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// ═══════════════════════════════════════════════════════════════
// AJOUT TÂCHE
// ═══════════════════════════════════════════════════════════════

struct AddTaskSheet: View {
    let date: Date
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var time = Date()
    @State private var duration = 30
    @State private var color: TaskColor = .blue
    
    var body: some View {
        NavigationView {
            Form {
                Section("Tâche") {
                    TextField("Nom de la tâche", text: $name)
                        .foregroundColor(AppColors.textPrimary)
                    
                    DatePicker("Heure", selection: $time, displayedComponents: .hourAndMinute)
                        .colorScheme(.dark)
                    
                    Stepper("Durée: \(duration) min", value: $duration, in: 5...180, step: 5)
                }
                
                Section("Couleur") {
                    HStack(spacing: 12) {
                        ForEach([TaskColor.blue, .green, .purple, .gold, .red], id: \.rawValue) { c in
                            Circle()
                                .fill(c.color)
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Circle().stroke(Color.white, lineWidth: color == c ? 2 : 0)
                                )
                                .onTapGesture { color = c }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppColors.bgPrimary)
            .navigationTitle("Nouvelle tâche")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") { dismiss() }
                        .foregroundColor(AppColors.textSecondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Ajouter") {
                        guard !name.isEmpty else { return }
                        let cal = Calendar.current
                        let h = cal.component(.hour, from: time)
                        let m = cal.component(.minute, from: time)
                        let timeStr = String(format: "%02d:%02d", h, m)
                        let task = DailyTask(id: UUID().uuidString, name: name, time: timeStr, duration: duration, type: .custom, color: color, isFixed: false)
                        store.addTask(task, date: date)
                        dismiss()
                    }
                    .foregroundColor(AppColors.accentGold)
                    .fontWeight(.semibold)
                    .disabled(name.isEmpty)
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}

// MARK: — Date helpers

extension Date {
    var startOfWeek: Date {
        let cal = Calendar.current
        let components = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return cal.date(from: components) ?? self
    }
}
