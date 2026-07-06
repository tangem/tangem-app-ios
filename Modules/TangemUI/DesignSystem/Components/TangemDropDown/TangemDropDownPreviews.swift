//
//  TangemDropDownPreviews.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

// MARK: - Showcase

public struct TangemDropDownShowcase: View {
    enum Category: TangemDropDownTextProvider {
        case all
        case fruits
        case vegetables

        var text: String {
            switch self {
            case .all: "All"
            case .fruits: "Fruits"
            case .vegetables: "Vegetables"
            }
        }
    }

    struct Item: Identifiable {
        let id = UUID()
        let name: String
        let emoji: String
        let category: Category
    }

    private let items: [Item] = [
        .init(name: "Apple", emoji: "🍎", category: .fruits),
        .init(name: "Banana", emoji: "🍌", category: .fruits),
        .init(name: "Orange", emoji: "🍊", category: .fruits),
        .init(name: "Mango", emoji: "🥭", category: .fruits),
        .init(name: "Carrot", emoji: "🥕", category: .vegetables),
        .init(name: "Broccoli", emoji: "🥦", category: .vegetables),
        .init(name: "Tomato", emoji: "🍅", category: .vegetables),
        .init(name: "Corn", emoji: "🌽", category: .vegetables),
    ]

    private let categories: [Category] = [.all, .fruits, .vegetables]
    @State private var selectedCategory: Category = .all
    @State private var sortByBalance = false
    @State private var groupByNetwork = false

    public init() {}

    private var filteredItems: [Item] {
        switch selectedCategory {
        case .all: items
        case .fruits: items.filter { $0.category == .fruits }
        case .vegetables: items.filter { $0.category == .vegetables }
        }
    }

    public var body: some View {
        VStack(spacing: 16) {
            Spacer()

            preview

            Spacer()
        }
        .padding()
        .background(Color.Tangem.Surface.level1)
    }

    private var preview: some View {
        VStack(alignment: .leading, spacing: 8) {
            TangemDropDown(singleSelection: $selectedCategory, in: categories)

            HStack {
                Text("Mixed items + custom label")
                    .font(.caption)
                Spacer()
                TangemDropDown(
                    items: [
                        TangemDropDownItem(
                            text: "Group by network",
                            isChecked: groupByNetwork,
                            action: { groupByNetwork.toggle() }
                        ),
                        TangemDropDownItem(
                            text: "Sort by balance",
                            isEnabled: !sortByBalance,
                            action: { sortByBalance = true }
                        ),
                    ],
                    label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .resizable()
                            .frame(width: 28, height: 28)
                    }
                )
            }

            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(filteredItems) { item in
                        HStack {
                            Text(item.emoji)
                                .font(.largeTitle)
                            Text(item.name)
                                .font(.body)
                            Spacer()
                            Text(item.category.text)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Interactive Demo") {
    TangemDropDownShowcase()
}
