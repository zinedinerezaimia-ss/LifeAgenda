import SwiftUI

struct MoneyView: View {
    @EnvironmentObject var store: AppStore
    @State private var showAdd = false
    @State private var newLabel = ""
    @State private var newAmount = ""
    @State private var newCategory = "🍔 Nourriture"
    @State private var isExpense = true
    
    let categories = ["🍔 Nourriture", "🚌 Transport", "👕 Vêtements", "📚 Education", "💪 Sport", "🎮 Loisirs", "💰 Revenus", "🏠 Logement", "📱 Abonnements", "🕌 Sadaqa"]
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Finances")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                }
                .padding(.horizontal, 20)
                .padding(.top, topSafeArea + 16)
                
                // Balance card
                balanceCard
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                
                // Add button
                Button {
                    showAdd = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Ajouter une transaction")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppColors.accentGold)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                // Transactions
                if !store.transactions.isEmpty {
                    Text("HISTORIQUE")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(AppColors.textMuted)
                        .kerning(1.5)
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        .padding(.bottom, 8)
                    
                    LazyVStack(spacing: 8) {
                        ForEach(store.transactions) { tx in
                            TransactionRow(transaction: tx)
                        }
                    }
                    .padding(.horizontal, 20)
                } else {
                    emptyState
                }
            }
            .padding(.bottom, 100)
        }
        .background(AppColors.bgPrimary)
        .sheet(isPresented: $showAdd) { addSheet }
    }
    
    private var balanceCard: some View {
        VStack(spacing: 16) {
            // Budget total
            VStack(spacing: 4) {
                Text("Solde disponible")
                    .font(.system(size: 13))
                    .foregroundColor(AppColors.textSecondary)
                Text(formatAmount(store.balance))
                    .font(.system(size: 38, weight: .bold))
                    .foregroundColor(store.balance >= 0 ? AppColors.accentGreen : AppColors.accentRed)
            }
            
            Rectangle()
                .fill(AppColors.border)
                .frame(height: 1)
            
            // Stats
            HStack {
                statItem(label: "Dépenses", value: store.transactions.filter { $0.isExpense }.reduce(0) { $0 + $1.amount }, color: AppColors.accentRed)
                Spacer()
                Rectangle().fill(AppColors.border).frame(width: 1, height: 30)
                Spacer()
                statItem(label: "Revenus", value: store.transactions.filter { !$0.isExpense }.reduce(0) { $0 + $1.amount }, color: AppColors.accentGreen)
            }
        }
        .padding(20)
        .background(AppColors.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func statItem(label: String, value: Double, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(formatAmount(abs(value)))
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(AppColors.textMuted)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func formatAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount)€"
    }
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Text("💰")
                .font(.system(size: 50))
            Text("Aucune transaction")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }
    
    private var addSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Type dépense/revenu
                HStack(spacing: 0) {
                    ForEach([(true, "💸 Dépense"), (false, "💰 Revenu")], id: \.0) { (expense, label) in
                        Button {
                            isExpense = expense
                        } label: {
                            Text(label)
                                .font(.system(size: 14, weight: isExpense == expense ? .semibold : .regular))
                                .foregroundColor(isExpense == expense ? .black : AppColors.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(isExpense == expense ? AppColors.accentGold : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
                .padding(4)
                .background(AppColors.bgCard)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
                
                // Montant
                HStack {
                    Text(isExpense ? "-" : "+")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(isExpense ? AppColors.accentRed : AppColors.accentGreen)
                    TextField("0.00", text: $newAmount)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                    Text("€")
                        .font(.system(size: 20))
                        .foregroundColor(AppColors.textMuted)
                }
                .padding()
                .background(AppColors.bgCard)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
                
                // Label
                TextField("Description (ex: Kebab Marché)", text: $newLabel)
                    .foregroundColor(AppColors.textPrimary)
                    .padding()
                    .background(AppColors.bgCard)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                
                // Catégories
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
                
                Spacer()
            }
            .padding(.top)
            .background(AppColors.bgPrimary.ignoresSafeArea())
            .navigationTitle("Nouvelle transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") { showAdd = false }
                        .foregroundColor(AppColors.textSecondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Ajouter") {
                        guard let amount = Double(newAmount.replacingOccurrences(of: ",", with: ".")) else { return }
                        let tx = Transaction(label: newLabel.isEmpty ? newCategory : newLabel, amount: isExpense ? -amount : amount, category: newCategory)
                        store.addTransaction(tx)
                        newAmount = ""
                        newLabel = ""
                        showAdd = false
                    }
                    .foregroundColor(AppColors.accentGold)
                    .fontWeight(.semibold)
                    .disabled(newAmount.isEmpty)
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

struct TransactionRow: View {
    let transaction: Transaction
    @EnvironmentObject var store: AppStore
    
    var body: some View {
        HStack(spacing: 12) {
            Text(transaction.category.components(separatedBy: " ").first ?? "")
                .font(.system(size: 22))
                .frame(width: 44, height: 44)
                .background(AppColors.bgSecondary)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.label)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                Text(transaction.date.formatted(.dateTime.day().month().hour().minute()))
                    .font(.system(size: 11))
                    .foregroundColor(AppColors.textMuted)
            }
            
            Spacer()
            
            Text(String(format: "%@%.2f€", transaction.amount >= 0 ? "+" : "", transaction.amount))
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(transaction.isExpense ? AppColors.accentRed : AppColors.accentGreen)
        }
        .padding(12)
        .background(AppColors.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .contextMenu {
            Button(role: .destructive) {
                store.deleteTransaction(id: transaction.id)
            } label: {
                Label("Supprimer", systemImage: "trash")
            }
        }
    }
}
