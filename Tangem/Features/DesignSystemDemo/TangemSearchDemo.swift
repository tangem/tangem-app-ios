//
//  TangemSearchDemo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemFoundation

final class TangemSearchDemoViewModel: ObservableObject, Identifiable {}

struct TangemSearchDemoView: View {
    @ObservedObject var viewModel: TangemSearchDemoViewModel

    @State private var selectedPlacement: TangemSearch.Placement?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            placementButton("Automatic", .automatic)
            placementButton("Top", .top)
            placementButton("Bottom", .bottom)

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(DesignSystem.Color.bgPrimary)
        .navigationTitle("TangemSearch")
        // Native `.searchable` placement is resolved once at presentation, so each placement is
        // shown on its own freshly pushed screen rather than toggled in place.
        .navigation(item: $selectedPlacement) { placement in
            TangemSearchPlacementDemoView(placement: placement)
        }
    }

    private func placementButton(_ title: String, _ placement: TangemSearch.Placement) -> some View {
        Button {
            selectedPlacement = placement
        } label: {
            Text(title)
                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
        }
    }
}

private struct TangemSearchPlacementDemoView: View {
    let placement: TangemSearch.Placement

    @State private var text: String = ""
    @State private var isActive: Bool = false

    private let items = [
        "Bitcoin", "Ethereum", "Solana", "Polygon",
        "Cardano", "Dogecoin", "Tether", "Litecoin",
    ]

    private var filteredItems: [String] {
        guard text.isNotEmpty else { return items }
        return items.filter { $0.localizedCaseInsensitiveContains(text) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("text: \"\(text)\" · active: \(isActive ? "true" : "false")")
                    .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textSecondary)

                ForEach(filteredItems, id: \.self) { item in
                    Text(item)
                        .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, .unit(.x2))
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Color.bgPrimary)
        .navigationTitle(title)
        .tangemSearchable(
            text: $text,
            isActive: $isActive,
            prompt: "Search",
            placement: placement
        )
    }

    private var title: String {
        switch placement {
        case .automatic: "Automatic"
        case .top: "Top"
        case .bottom: "Bottom"
        }
    }
}
