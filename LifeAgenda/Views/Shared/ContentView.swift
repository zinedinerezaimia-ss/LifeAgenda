import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Tab = .agenda
    
    enum Tab: Int, CaseIterable {
        case agenda, ideas, sport, money
        
        var title: String {
            switch self {
            case .agenda: return "Agenda"
            case .ideas:  return "Idées"
            case .sport:  return "Sport"
            case .money:  return "Argent"
            }
        }
        
        var icon: String {
            switch self {
            case .agenda: return "calendar"
            case .ideas:  return "lightbulb"
            case .sport:  return "dumbbell"
            case .money:  return "dollarsign.circle"
            }
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Tab content
            Group {
                switch selectedTab {
                case .agenda: AgendaView()
                case .ideas:  IdeasView()
                case .sport:  SportView()
                case .money:  MoneyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Custom Tab Bar
            CustomTabBar(selectedTab: $selectedTab)
        }
        .background(AppColors.bgPrimary)
        .ignoresSafeArea(edges: .bottom)
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: ContentView.Tab
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(ContentView.Tab.allCases, id: \.rawValue) { tab in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 22, weight: selectedTab == tab ? .semibold : .regular))
                            .foregroundColor(selectedTab == tab ? AppColors.accentGold : AppColors.textMuted)
                        Text(tab.title)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(selectedTab == tab ? AppColors.accentGold : AppColors.textMuted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                }
            }
        }
        .padding(.bottom, bottomSafeArea)
        .background(
            AppColors.bgSecondary
                .overlay(
                    Rectangle()
                        .frame(height: 0.5)
                        .foregroundColor(AppColors.border),
                    alignment: .top
                )
        )
    }
    
    private var bottomSafeArea: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.safeAreaInsets.bottom ?? 0
    }
}
