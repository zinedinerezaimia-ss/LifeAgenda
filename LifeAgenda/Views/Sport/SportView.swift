import SwiftUI

// ═══════════════════════════════════════════════════════════════
// SPORT VIEW
// ═══════════════════════════════════════════════════════════════

struct SportView: View {
    @State private var selectedSegment = 0
    private let segments = ["Matin", "Après-midi", "Étirements"]
    
    private var todayWeekday: Int {
        Calendar.current.component(.weekday, from: Date()) - 1 // 0=Sun
    }
    
    private var afternoonSession: WorkoutSession {
        SportProgram.afternoonSession(for: todayWeekday)
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Programme Sport")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                    Text(Date().formatted(.dateTime.weekday(.wide).day().month()))
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, topSafeArea + 16)
                
                // Rotation info
                weekRotationView
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                
                // Segment picker
                HStack(spacing: 0) {
                    ForEach(Array(segments.enumerated()), id: \.offset) { idx, seg in
                        Button {
                            withAnimation(.spring(response: 0.3)) { selectedSegment = idx }
                        } label: {
                            Text(seg)
                                .font(.system(size: 13, weight: selectedSegment == idx ? .semibold : .regular))
                                .foregroundColor(selectedSegment == idx ? .black : AppColors.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(selectedSegment == idx ? AppColors.accentGold : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
                .padding(4)
                .background(AppColors.bgCard)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // Session content
                Group {
                    switch selectedSegment {
                    case 0: SessionView(session: SportProgram.morning, duration: "15 min")
                    case 1: SessionView(session: afternoonSession, duration: "45 min")
                    default: SessionView(session: SportProgram.stretch, duration: "15 min")
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 100)
            }
        }
        .background(AppColors.bgPrimary)
    }
    
    private var weekRotationView: some View {
        let days   = ["D", "L", "M", "M", "J", "V", "S"]
        let labels = ["PUSH", "PULL", "LEGS", "PUSH", "PULL", "LEGS", "ABS"]
        let colors: [Color] = [.orange, .cyan, .purple, .orange, .cyan, .purple, .green]
        
        return HStack(spacing: 6) {
            ForEach(0..<7) { i in
                VStack(spacing: 4) {
                    Text(days[i])
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(i == todayWeekday ? .black : AppColors.textMuted)
                    Text(labels[i])
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(i == todayWeekday ? .black : colors[i])
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(i == todayWeekday ? AppColors.accentGold : colors[i].opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
    
    private var topSafeArea: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.safeAreaInsets.top ?? 44
    }
}

struct SessionView: View {
    let session: WorkoutSession
    let duration: String
    @State private var expandedExercise: String? = nil
    
    var body: some View {
        VStack(spacing: 14) {
            // Titre séance
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(session.emoji)
                            .font(.system(size: 24))
                        Text(session.title)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(AppColors.textPrimary)
                    }
                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .font(.system(size: 11))
                        Text(duration)
                            .font(.system(size: 13))
                    }
                    .foregroundColor(AppColors.textSecondary)
                }
                Spacer()
            }
            .padding(16)
            .background(AppColors.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Exercices
            ForEach(Array(session.exercises.enumerated()), id: \.element.id) { idx, ex in
                ExerciseRow(exercise: ex, index: idx + 1, isExpanded: expandedExercise == ex.id) {
                    withAnimation(.spring(response: 0.3)) {
                        expandedExercise = expandedExercise == ex.id ? nil : ex.id
                    }
                }
            }
        }
    }
}

struct ExerciseRow: View {
    let exercise: Exercise
    let index: Int
    let isExpanded: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: onTap) {
                HStack(spacing: 14) {
                    Text("\(index)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.black)
                        .frame(width: 28, height: 28)
                        .background(AppColors.accentGold)
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(exercise.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppColors.textPrimary)
                        Text(exercise.reps)
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.accentGold)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textMuted)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
            
            if isExpanded {
                HStack {
                    Rectangle()
                        .fill(AppColors.accentGold.opacity(0.4))
                        .frame(width: 2)
                        .padding(.leading, 28)
                    
                    Text(exercise.desc)
                        .font(.system(size: 13))
                        .foregroundColor(AppColors.textSecondary)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                    
                    Spacer()
                }
            }
        }
        .background(AppColors.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
