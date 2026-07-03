import SwiftUI
import SwiftData

struct InventoryListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \ChemicalProduct.name) private var products: [ChemicalProduct]

    @State private var showingAdd = false
    @State private var editingProduct: ChemicalProduct?
    @State private var showingUnits = false

    private var groupedByKind: [(ChemicalKind, [ChemicalProduct])] {
        let grouped = Dictionary(grouping: products, by: \.chemicalKind)
        return ChemicalKind.allCases.compactMap { kind in
            guard let items = grouped[kind], !items.isEmpty else { return nil }
            return (kind, items)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if products.isEmpty {
                    EmptyStateView(
                        systemImage: "shippingbox.fill",
                        title: "No Chemicals Yet",
                        message: "Add the chemicals you keep on hand so Chemie can suggest what to use — and warn you before you run out.",
                        actionTitle: "Add Chemical"
                    ) {
                        showingAdd = true
                    }
                    .screenBackground()
                } else {
                    List {
                        ForEach(groupedByKind, id: \.0) { kind, items in
                            Section(kind.displayName) {
                                ForEach(items) { product in
                                    Button {
                                        editingProduct = product
                                    } label: {
                                        ProductRow(product: product)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .onDelete { offsets in
                                    delete(items: items, at: offsets)
                                }
                            }
                            .listRowBackground(Theme.surface)
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .screenBackground()
                }
            }
            .navigationTitle("Inventory")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingUnits = true
                    } label: {
                        Image(systemName: "ruler.fill")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAdd) {
                InventoryEditView(product: nil)
            }
            .sheet(item: $editingProduct) { product in
                InventoryEditView(product: product)
            }
            .sheet(isPresented: $showingUnits) {
                UnitEditorView()
            }
        }
    }

    private func delete(items: [ChemicalProduct], at offsets: IndexSet) {
        for index in offsets {
            context.delete(items[index])
        }
        try? context.save()
    }
}

private struct ProductRow: View {
    let product: ChemicalProduct

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: product.formType.sfSymbol)
                .foregroundStyle(Theme.accentAqua)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 3) {
                Text(product.name)
                    .font(Theme.Font.body())
                    .foregroundStyle(Theme.textPrimary)
                HStack(spacing: 6) {
                    if !product.brand.isEmpty {
                        Text(product.brand)
                    }
                    Text(product.formType.rawValue)
                }
                .font(Theme.Font.caption())
                .foregroundStyle(Theme.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(InventoryMonitor.formattedQuantity(product))
                    .font(Theme.Font.headline())
                    .foregroundStyle(product.isLowStock ? Theme.warning : Theme.textPrimary)
                if product.isLowStock {
                    TextBadge(text: "Low Stock", color: Theme.warning, filled: true)
                } else if product.isExpired {
                    TextBadge(text: "Expired", color: Theme.danger, filled: true)
                } else if product.isExpiringSoon {
                    TextBadge(text: "Expiring Soon", color: Theme.warning)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
