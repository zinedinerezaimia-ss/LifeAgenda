import Foundation
import SwiftUI

// ═══════════════════════════════════════════════════════════════
// MODÈLES DE DONNÉES
// ═══════════════════════════════════════════════════════════════

enum TaskType: String, Codable, CaseIterable {
    case prayer, sport, quran, stretch, custom
}

enum TaskColor: String, Codable {
    case gold, green, blue, purple, red
    
    var color: Color {
        switch self {
        case .gold:   return AppColors.accentGold
        case .green:  return AppColors.accentGreen
        case .blue:   return AppColors.accentBlue
        case .purple: return AppColors.accentPurple
        case .red:    return AppColors.accentRed
        }
    }
    
    var dimColor: Color { color.opacity(0.15) }
}

struct DailyTask: Identifiable, Codable {
    var id: String
    var name: String
    var time: String       // "HH:mm"
    var duration: Int      // minutes
    var type: TaskType
    var color: TaskColor
    var isFixed: Bool
    var note: String?
    
    // Heure en minutes pour tri
    var timeInMinutes: Int {
        let parts = time.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { return 0 }
        return parts[0] * 60 + parts[1]
    }
}

struct Punishment: Identifiable, Codable {
    var id: String
    var name: String
    var description: String
}

// État de complétion d'une tâche pour une date
typealias DateString = String  // "yyyy-MM-dd"
typealias TaskID = String

// Données partagées avec App Group (Iqra)
struct SharedAgendaData: Codable {
    var dailyStreak: Int
    var todayProgress: Double  // 0.0 - 1.0
    var lastUpdated: Date
    var completedToday: [TaskID]
    
    static var empty: SharedAgendaData {
        SharedAgendaData(
            dailyStreak: 0,
            todayProgress: 0,
            lastUpdated: Date(),
            completedToday: []
        )
    }
}

// ═══════════════════════════════════════════════════════════════
// DONNÉES FIXES (axes quotidiens)
// ═══════════════════════════════════════════════════════════════

extension DailyTask {
    static let fixedAxes: [DailyTask] = [
        DailyTask(id: "prayer_fajr",      name: "Fajr 🌅",              time: "05:30", duration: 10, type: .prayer,  color: .gold,   isFixed: true),
        DailyTask(id: "sport_morning",    name: "Sport Matin 💪",        time: "07:40", duration: 15, type: .sport,   color: .green,  isFixed: true),
        DailyTask(id: "prayer_dhuhr",     name: "Dhuhr ☀️",              time: "13:04", duration: 10, type: .prayer,  color: .gold,   isFixed: true),
        DailyTask(id: "sport_afternoon",  name: "Sport Après-midi 🔥",   time: "14:46", duration: 45, type: .sport,   color: .green,  isFixed: true),
        DailyTask(id: "prayer_asr",       name: "Asr 🌤️",               time: "16:30", duration: 10, type: .prayer,  color: .gold,   isFixed: true),
        DailyTask(id: "prayer_maghrib",   name: "Maghrib 🌅",            time: "18:00", duration: 10, type: .prayer,  color: .gold,   isFixed: true),
        DailyTask(id: "quran",            name: "Coran 📖",              time: "18:30", duration: 30, type: .quran,   color: .purple, isFixed: true),
        DailyTask(id: "prayer_isha",      name: "Isha 🌙",               time: "19:30", duration: 10, type: .prayer,  color: .gold,   isFixed: true),
        DailyTask(id: "stretch",          name: "Étirements 🧘",         time: "22:00", duration: 15, type: .stretch, color: .blue,   isFixed: true),
    ]
}

// ═══════════════════════════════════════════════════════════════
// PROGRAMME SPORT
// ═══════════════════════════════════════════════════════════════

struct Exercise: Identifiable, Codable {
    let id: String
    let name: String
    let reps: String
    let desc: String
    
    init(name: String, reps: String, desc: String) {
        self.id = UUID().uuidString
        self.name = name
        self.reps = reps
        self.desc = desc
    }
}

struct WorkoutSession: Identifiable {
    let id: String
    let title: String
    let emoji: String
    let exercises: [Exercise]
    
    init(title: String, emoji: String, exercises: [Exercise]) {
        self.id = UUID().uuidString
        self.title = title
        self.emoji = emoji
        self.exercises = exercises
    }
}

struct SportProgram {
    static let morning = WorkoutSession(
        title: "Réveil Musculaire",
        emoji: "⚡️",
        exercises: [
            Exercise(name: "Jumping Jacks",       reps: "30 sec",     desc: "Sauts avec bras et jambes écartés, cardio pour réveiller le corps"),
            Exercise(name: "Mountain Climbers",    reps: "30 sec",     desc: "Position pompe, ramener les genoux alternativement vers la poitrine rapidement"),
            Exercise(name: "Pompes",               reps: "15 reps",    desc: "Mains largeur épaules, descendre poitrine au sol, dos droit"),
            Exercise(name: "Squats",               reps: "20 reps",    desc: "Pieds largeur épaules, descendre fesses en arrière, cuisses parallèles au sol"),
            Exercise(name: "Planche",              reps: "45 sec",     desc: "Sur les avant-bras, corps aligné, gainage abdominal"),
            Exercise(name: "Burpees",              reps: "10 reps",    desc: "Squat → pompe → saut, exercice complet pour brûler"),
        ]
    )
    
    static let push = WorkoutSession(
        title: "PUSH — Pec / Épaules / Tri",
        emoji: "💪",
        exercises: [
            Exercise(name: "Pompes larges",    reps: "4×15",       desc: "Mains très écartées, cible les pectoraux externes"),
            Exercise(name: "Pompes diamant",   reps: "3×12",       desc: "Mains en diamant sous la poitrine, cible triceps et pecs internes"),
            Exercise(name: "Pompes déclinées", reps: "3×12",       desc: "Pieds surélevés sur chaise, cible haut des pectoraux"),
            Exercise(name: "Pike Push-ups",    reps: "4×10",       desc: "Corps en V inversé, descendre tête vers le sol, cible épaules"),
            Exercise(name: "Dips sur chaise",  reps: "4×12",       desc: "Mains sur chaise derrière, descendre et remonter, triceps"),
            Exercise(name: "Pompes archer",    reps: "3×8/côté",   desc: "Une main large, l'autre proche, alterner, force unilatérale"),
        ]
    )
    
    static let pull = WorkoutSession(
        title: "PULL — Dos / Biceps",
        emoji: "🏋️",
        exercises: [
            Exercise(name: "Rowing inversé",         reps: "4×12",       desc: "Sous une table, tirer la poitrine vers le bord, dos"),
            Exercise(name: "Superman",                reps: "4×15",       desc: "Allongé ventre, lever bras et jambes simultanément"),
            Exercise(name: "Rowing serviette",        reps: "4×12/côté",  desc: "Serviette autour poignée porte, tirer vers soi"),
            Exercise(name: "Back extension",          reps: "3×15",       desc: "Allongé ventre, lever le buste, renforcement lombaires"),
            Exercise(name: "Curl isométrique",        reps: "3×30 sec",   desc: "Serviette sous le pied, tirer et maintenir, biceps"),
            Exercise(name: "Planche tap épaules",     reps: "3×20",       desc: "Position pompe, toucher épaule opposée alternativement"),
        ]
    )
    
    static let legs = WorkoutSession(
        title: "LEGS — Jambes / Fessiers",
        emoji: "🦵",
        exercises: [
            Exercise(name: "Squats sautés",     reps: "4×15",       desc: "Squat puis explosion vers le haut, puissance"),
            Exercise(name: "Fentes marchées",   reps: "4×12/jambe", desc: "Grand pas avant, genou 90°, alterner en avançant"),
            Exercise(name: "Squats bulgares",   reps: "3×10/jambe", desc: "Pied arrière sur chaise, squat unijambiste, killer pour les fessiers"),
            Exercise(name: "Pont fessier",      reps: "4×20",       desc: "Dos au sol, pousser hanches vers le haut, serrer fessiers"),
            Exercise(name: "Wall sit",          reps: "3×45 sec",   desc: "Dos au mur, cuisses parallèles au sol, maintenir"),
            Exercise(name: "Calf raises",       reps: "4×25",       desc: "Sur une marche, monter sur la pointe des pieds, mollets"),
        ]
    )
    
    static let abs = WorkoutSession(
        title: "ABS — Abdominaux",
        emoji: "🎯",
        exercises: [
            Exercise(name: "Crunchs",            reps: "4×25",       desc: "Dos au sol, lever épaules, contracter les abdos hauts"),
            Exercise(name: "Leg raises",         reps: "4×15",       desc: "Dos au sol, lever jambes tendues à 90°, abdos bas"),
            Exercise(name: "Russian twists",     reps: "4×20",       desc: "Assis, pieds levés, tourner le buste gauche/droite"),
            Exercise(name: "Planche latérale",   reps: "3×30 sec/côté", desc: "Sur un avant-bras, corps aligné, obliques"),
            Exercise(name: "Bicycle crunch",     reps: "4×20",       desc: "Coude vers genou opposé, mouvement vélo"),
            Exercise(name: "Dead bug",           reps: "3×12/côté",  desc: "Dos au sol, étendre bras et jambe opposés"),
        ]
    )
    
    static let stretch = WorkoutSession(
        title: "Récupération & Mobilité",
        emoji: "🧘",
        exercises: [
            Exercise(name: "Étirement pectoraux",      reps: "45 sec/côté", desc: "Bras contre mur, tourner le corps, ouvrir la poitrine"),
            Exercise(name: "Étirement épaules",        reps: "30 sec/côté", desc: "Bras devant, tirer avec l'autre main vers la poitrine"),
            Exercise(name: "Chat-vache",               reps: "10 cycles",   desc: "4 pattes, alterner dos creux et dos rond, mobilité colonne"),
            Exercise(name: "Pigeon pose",              reps: "60 sec/côté", desc: "Jambe avant pliée, arrière tendue, ouvrir les hanches"),
            Exercise(name: "Étirement ischio-jamb.",   reps: "45 sec/jambe",desc: "Jambe sur support, pencher vers l'avant"),
            Exercise(name: "Child's pose",             reps: "60 sec",      desc: "Assis sur talons, bras tendus devant, relaxation totale"),
        ]
    )
    
    // Rotation : Dim=Push, Lun=Pull, Mar=Legs, Mer=Push, Jeu=Pull, Ven=Legs, Sam=Abs
    static let afternoonRotation: [Int: WorkoutSession] = [
        0: push, 1: pull, 2: legs, 3: push, 4: pull, 5: legs, 6: abs
    ]
    
    static func afternoonSession(for weekday: Int) -> WorkoutSession {
        afternoonRotation[weekday] ?? abs
    }
}

// ═══════════════════════════════════════════════════════════════
// PUNITIONS
// ═══════════════════════════════════════════════════════════════

extension Punishment {
    static let defaults: [Punishment] = [
        Punishment(id: "harder_workout", name: "🔥 Séance plus dure",    description: "+10 reps sur chaque exercice demain"),
        Punishment(id: "no_fcmobile",   name: "⚽ Pas de FC Mobile",     description: "Interdit de jouer à FC Mobile aujourd'hui"),
        Punishment(id: "no_tiktok",     name: "📵 Pas de TikTok",        description: "Pas de TikTok pour le reste de la journée"),
    ]
}
