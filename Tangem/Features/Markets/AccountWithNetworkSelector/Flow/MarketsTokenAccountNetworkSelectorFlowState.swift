//
//  MarketsTokenAccountNetworkSelectorFlowState.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

extension MarketsTokenAccountNetworkSelectorFlowViewModel {
    /// Defines the navigation context for a given state
    enum NavigationContext: Equatable {
        case root
        case fromAddToken
        case fromChooseAccount
    }

    enum ViewState: Equatable {
        case accountSelector(viewModel: AccountSelectorViewModel, context: NavigationContext)
        case networksSelection(viewModel: MarketsNetworkSelectorViewModel, context: NavigationContext)
        case addToken(viewModel: MarketsAddTokenViewModel)
        case getToken(viewModel: MarketsGetTokenViewModel)

        var id: String {
            switch self {
            case .accountSelector:
                "accountSelector"
            case .networksSelection:
                "networksSelection"
            case .addToken:
                "addToken"
            case .getToken:
                "getToken"
            }
        }

        /// Returns true if the current state allows back navigation
        var canGoBack: Bool {
            switch self {
            case .accountSelector(_, let context):
                return context == .fromAddToken

            case .networksSelection(_, let context):
                return context != .root

            case .addToken:
                return false

            case .getToken:
                return false
            }
        }

        /// Returns true if the current state allows close navigation
        var canBeClosed: Bool {
            switch self {
            case .accountSelector(_, let context):
                return context != .fromAddToken

            case .networksSelection(_, let context):
                return context != .fromAddToken

            case .addToken:
                return true

            case .getToken:
                return true
            }
        }

        // MARK: - Equatable

        static func == (
            lhs: MarketsTokenAccountNetworkSelectorFlowViewModel.ViewState,
            rhs: MarketsTokenAccountNetworkSelectorFlowViewModel.ViewState
        ) -> Bool {
            switch (lhs, rhs) {
            case (.accountSelector, .accountSelector):
                return true
            case (.networksSelection, .networksSelection):
                return true
            case (.addToken, .addToken):
                return true
            case (.getToken, .getToken):
                return true
            default:
                return false
            }
        }
    }
}
