import SwiftUI

struct IdeasView: View {
    @EnvironmentObject var store: AppStore
    @State private var showAdd = false
    @State private var newText = ""
    @State private var newCategory = "💡 Général"
    
    let categories = ["💡 Général", "🎯 Objectifs", "💼 Business", "📚 Apprentissage", "🌙 Spirituel", "💪 Sport"]
    
    var pinnedIdeas: [IdeaItem] { store.ideas.filter { $0.isPinned } }
    var otherIdeas:  [IdeaItem] { store.ideas.filter { !$0.isPinned } }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Idées & Notes")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(AppColors.textPrimary)
                        Text("\(store.ideas.count) note\(store.ideas.count != 1 ? "s" : "")")
                            .font(.system(size: 13))
                            .foregroundColor(AppColors.textSecondary)
                    }
                    Spacer()
                    Button {
                        showAdd = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.black)
                            .frame(width: 40, height: 40)
                            .background(AppColors.accentGold)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, topSafeArea + 16)
                
                if store.ideas.isEmpty {
                    emptyState
                } else {
                    // Épinglées
                    if !pinnedIdeas.isEmpty {
                        sectionHeader("📌 Épinglées")
                        LazyVStack(spacing: 10) {
                            ForEach(pinnedIdeas) { idea in
                                IdeaCard(idea: idea)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Autres
                    if !otherIdeas.isEmpty {
                        sectionHeader("📝 Toutes les notes")
                        LazyVStack(spacing: 10) {
                            ForEach(otherIdeas) { idea in
                                IdeaCard(idea: idea)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
            .padding(.bottom, 100)
        }
        .background(AppColors.bgPrimary)
        .sheet(isPresented: $showAdd) {
            addSheet
        }
    }
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(AppColors.textMuted)
            .kerning(1)
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 8)
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Text("💡")
                .font(.system(size: 60))
            Text("Aucune idée pour l'instant")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppColors.textSecondary)
            Text("Appuie sur + pour noter\ntes idées, objectifs et projets.")
                .font(.system(size: 14))
                .foregroundColor(AppColors.textMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }
    
    private var addSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Catégorie
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat)
                                .font(.system(size: 13))
                                .foregroundColor(newCategory == cat ? .black : AppColors.textSecondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(newCategory == cat ? AppColors.accentGold : AppColors.bgCard)
                                .clipShape(Capsule())
                                .onTapGesture { newCategory = cat }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Text editor
                ZStack(alignment: .topLeading) {
                    if newText.isEmpty {
                        Text("Note ton idée ici…")
                            .foregroundColor(AppColors.textMuted)
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                    }
                    TextEditor(text: $newText)
                        .foregroundColor(AppColors.textPrimary)
                        .padding(12)
                        .frame(minHeight: 150)
                        .scrollContentBackground(.hidden)
                }
                .background(AppColors.bgCard)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top)
            .background(AppColors.bgPrimary.ignoresSafeArea())
            .navigationTitle("Nouvelle note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") { showAdd = false }
                        .foregroundColor(AppColors.textSecondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Ajouter") {
                        guard !newText.isEmpty else { return }
                        let idea = IdeaItem(text: newText, category: newCategory)
                        store.addIdea(idea)
                        newText = ""
                        showAdd = false
                    }
                    .foregroundColor(AppColors.accentGold)
                    .fontWeight(.semibold)
                    .disabled(newText.isEmpty)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private var topSafeArea: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.safeAreaInsets.top ?? 44
    }
}

struct IdeaCard: View {
    let idea: IdeaItem
    @EnvironmentObject var store: AppStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(idea.category)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(AppColors.accentGold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(AppColors.accentGold.opacity(0.15))
                    .clipShape(Capsule())
                
                Spacer()
                
                Text(idea.date.formatted(.dateTime.day().month()))
                    .font(.system(size: 11))
                    .foregroundColor(AppColors.textMuted)
            }
            
            Text(idea.text)
                .font(.system(size: 14))
                .foregroundColor(AppColors.textPrimary)
                .lineLimit(4)
        }
        .padding(14)
        .background(AppColors.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .contextMenu {
            Button {
                var updated = idea
                updated.isPinned.toggle()
                store.deleteIdea(id: idea.id)
                store.addIdea(updated)
            } label: {
                Label(idea.isPinned ? "Désépingler" : "Épingler", systemImage: idea.isPinned ? "pin.slash" : "pin")
            }
            Button(role: .destructive) {
                store.deleteIdea(id: idea.id)
            } label: {
                Label("Supprimer", systemImage: "trash")
            }
        }
    }
}
