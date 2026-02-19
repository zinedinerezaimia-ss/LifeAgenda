import SwiftUI

// ═══════════════════════════════════════════════════════════════
// DESIGN SYSTEM — LifeAgenda (identique à Iqra)
// ═══════════════════════════════════════════════════════════════

enum AppColors {
    static let bgPrimary     = Color(hex: "#0a0a0a")
    static let bgSecondary   = Color(hex: "#141414")
    static let bgCard        = Color(hex: "#1a1a1a")
    static let bgCardHover   = Color(hex: "#222222")
    static let accentGold    = Color(hex: "#d4a853")
    static let accentGreen   = Color(hex: "#2dd4bf")
    static let accentRed     = Color(hex: "#ef4444")
    static let accentBlue    = Color(hex: "#3b82f6")
    static let accentPurple  = Color(hex: "#a855f7")
    static let textPrimary   = Color(hex: "#f5f5f5")
    static let textSecondary = Color(hex: "#a0a0a0")
    static let textMuted     = Color(hex: "#666666")
    static let border        = Color(hex: "#2a2a2a")
    
    static func forTaskType(_ type: TaskType) -> Color {
        switch type {
        case .prayer: return accentGold
        case .sport:  return accentGreen
        case .quran:  return accentPurple
        case .custom: return accentBlue
        case .stretch: return accentBlue
        }
    }
}

enum AppFonts {
    static func outfit(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom("Outfit", size: size).weight(weight)
    }
    static func mono(_ size: CGFloat) -> Font {
        .custom("SpaceMono-Regular", size: size)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red:   Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// Reusable card modifier
struct CardStyle: ViewModifier {
    var color: Color = AppColors.bgCard
    func body(content: Content) -> some View {
        content
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

extension View {
    func cardStyle(_ color: Color = AppColors.bgCard) -> some View {
        modifier(CardStyle(color: color))
    }
}
