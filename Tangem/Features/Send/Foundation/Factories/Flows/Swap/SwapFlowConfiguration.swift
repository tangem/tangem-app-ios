//
//  SwapFlowConfiguration.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

/// Per-flow tweaks for the swap screen. An entry point that pins one side of the pair uses these
/// to keep it pinned and to title the flow; every other swap entry keeps `.default`.
struct SwapFlowConfiguration {
    /// When `false`, the source/receive reverse button is hidden.
    let isPairReversalEnabled: Bool
    /// What the source token selector offers.
    let sourceTokenSelection: TokenSelection
    /// How the receive side may change.
    let receiveTokenSelection: ReceiveTokenSelection
    /// Overrides the swap summary navigation title.
    let summaryTitle: String?

    static let `default` = SwapFlowConfiguration(
        isPairReversalEnabled: true,
        sourceTokenSelection: .unrestricted,
        receiveTokenSelection: .selectable(.unrestricted),
        summaryTitle: nil
    )
}

extension SwapFlowConfiguration {
    enum TokenSelection {
        case unrestricted
        /// The full list minus items the predicate rejects; markets search stays available.
        case filtered(isIncluded: (TokenSelectorItem) -> Bool)
        /// The token can only be picked from the given provider's content. Markets search is the
        /// flow's own call — a pinned list may still let the user add a token from markets.
        case restricted(walletsProvider: any TokenSelectorWalletsProvider, allowsMarketsTokens: Bool)

        var walletsProvider: (any TokenSelectorWalletsProvider)? {
            switch self {
            case .unrestricted: nil
            case .filtered(let isIncluded): FilteredTokenSelectorWalletsProvider(base: .common(), isIncluded: isIncluded)
            case .restricted(let walletsProvider, _): walletsProvider
            }
        }

        var allowsMarketsTokens: Bool {
            switch self {
            case .unrestricted, .filtered: true
            case .restricted(_, let allowsMarketsTokens): allowsMarketsTokens
            }
        }
    }

    enum ReceiveTokenSelection {
        case selectable(TokenSelection)
        /// Re-derived from the source on every source change.
        case followsSource(any SwapDestinationTokenResolver)

        var isSelectionEnabled: Bool {
            switch self {
            case .selectable: true
            case .followsSource: false
            }
        }

        var walletsProvider: (any TokenSelectorWalletsProvider)? {
            switch self {
            case .selectable(let selection): selection.walletsProvider
            case .followsSource: nil
            }
        }

        var destinationResolver: (any SwapDestinationTokenResolver)? {
            switch self {
            case .followsSource(let resolver): resolver
            case .selectable: nil
            }
        }

        var allowsMarketsTokens: Bool {
            switch self {
            case .selectable(let selection): selection.allowsMarketsTokens
            case .followsSource: false
            }
        }
    }
}
