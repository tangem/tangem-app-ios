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
    let sourceTokenSelection: SourceTokenSelection
    /// How the receive side may change.
    let receiveTokenSelection: ReceiveTokenSelection
    /// Overrides the swap summary navigation title.
    let summaryTitle: String?

    static let `default` = SwapFlowConfiguration(
        isPairReversalEnabled: true,
        sourceTokenSelection: .unrestricted,
        receiveTokenSelection: .unrestricted,
        summaryTitle: nil
    )
}

extension SwapFlowConfiguration {
    enum SourceTokenSelection {
        case unrestricted
        /// The source can only be picked from the given provider's content.
        case restricted(walletsProvider: any TokenSelectorWalletsProvider)

        var restrictedWalletsProvider: (any TokenSelectorWalletsProvider)? {
            switch self {
            case .unrestricted: nil
            case .restricted(let walletsProvider): walletsProvider
            }
        }
    }

    enum ReceiveTokenSelection {
        case unrestricted
        /// Pinned to the initial token.
        case locked
        /// Not user-selectable; re-derived from the source on every source change.
        case followsSource(any SwapDestinationTokenResolver)

        var isSelectionEnabled: Bool {
            switch self {
            case .unrestricted: true
            case .locked, .followsSource: false
            }
        }

        var destinationResolver: (any SwapDestinationTokenResolver)? {
            switch self {
            case .followsSource(let resolver): resolver
            case .unrestricted, .locked: nil
            }
        }
    }
}
