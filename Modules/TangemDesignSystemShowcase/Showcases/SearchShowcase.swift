//
//  SearchShowcase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

#if INTERNAL || DEBUG
import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct SearchShowcase: View {
    @State private var text = ""
    @State private var isActive = false
    @State private var placeholder = "Crypto, stocks and more"
    @State private var showsCloseButton = true
    @State private var interactiveGlass = true
    @State private var clearTaps = 0
    @State private var cancelTaps = 0
    @State private var pushedPlacement: Search.Placement = .automatic
    @State private var isPlacementPushed = false

    var body: some View {
        DSShowcase("Search", layout: .fill) { controls in
            controls.text("Placeholder", $placeholder)
            controls.toggle("Close button", $showsCloseButton)
            controls.toggle("Interactive glass", $interactiveGlass)
            controls.toggle("Active", $isActive)
            controls.readout("Text", "\"\(text)\"")
            controls.readout("Clear / cancel taps", "\(clearTaps) / \(cancelTaps)")
            controls.note("tangemSearchable resolves the native placement once at presentation, so each placement opens on its own freshly pushed screen.")

            ForEach(Self.placements, id: \.self) { placement in
                controls.action("tangemSearchable · \(Self.title(for: placement))") {
                    pushedPlacement = placement
                    isPlacementPushed = true
                }
            }
        } stage: {
            VStack(spacing: 0) {
                Search(
                    text: $text,
                    isActive: $isActive,
                    clearAction: { clearTaps += 1 },
                    cancelAction: { cancelTaps += 1 }
                )
                .placeholder(placeholder)
                .showsCloseButton(showsCloseButton)
                .interactiveGlass(interactiveGlass)
                .padding(16)

                SearchShowcaseTokenList(query: text)
            }
            .navigationDestination(isPresented: $isPlacementPushed) {
                SearchPlacementScreen(placement: pushedPlacement)
            }
        } matrix: {
            DSShowcaseMatrix(
                rows: FieldState.allCases,
                columns: [true, false],
                columnLabel: { $0 ? "interactive glass" : "static glass" }
            ) { state, interactiveGlass in
                Search(text: .constant(state.text))
                    .placeholder("Crypto, stocks and more")
                    .interactiveGlass(interactiveGlass)
                    .frame(width: 280)
            }
        }
    }

    private static var placements: [Search.Placement] {
        [.automatic, .top, .bottom]
    }

    fileprivate static func title(for placement: Search.Placement) -> String {
        switch placement {
        case .automatic: "Automatic"
        case .top: "Top"
        case .bottom: "Bottom"
        }
    }
}

private extension SearchShowcase {
    enum FieldState: CaseIterable {
        case placeholder
        case filled
        case long

        var text: String {
            switch self {
            case .placeholder: ""
            case .filled: "Bitcoin"
            case .long: "Wrapped Bitcoin on Arbitrum One bridged via Stargate"
            }
        }
    }
}

private struct SearchPlacementScreen: View {
    let placement: Search.Placement

    @State private var text = ""
    @State private var isActive = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("text: \"\(text)\" · active: \(isActive ? "true" : "false")")
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

            SearchShowcaseTokenList(query: text)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
        .navigationTitle(SearchShowcase.title(for: placement))
        .navigationBarTitleDisplayMode(.inline)
        .tangemSearchable(
            text: $text,
            isActive: $isActive,
            prompt: "Search tokens",
            placement: placement
        )
    }
}

private struct SearchShowcaseTokenList: View {
    let query: String

    private let tokens = [
        "Bitcoin", "Ethereum", "Solana", "Polygon", "Cardano", "Dogecoin",
        "Tether", "Litecoin", "USD Coin", "Wrapped Bitcoin", "Toncoin", "Avalanche",
    ]

    private var filteredTokens: [String] {
        query.isEmpty ? tokens : tokens.filter { $0.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(filteredTokens, id: \.self) { token in
                    Text(token)
                        .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                }
            }
        }
    }
}
#endif
