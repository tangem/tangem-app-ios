//
//  AccountsAwareAddTokenFlowState.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

extension AccountsAwareAddTokenFlowViewModel {
    /// Defines the navigation context for a given state
    enum NavigationContext: Equatable {
        case root
        case fromAddToken
        case fromChooseAccount
    }

    enum ViewState: Equatable {
        case accountSelector(viewModel: AccountSelectorViewModel, context: NavigationContext)
        case networkSelector(viewModel: AccountsAwareNetworkSelectorViewModel, context: NavigationContext)
        case addToken(viewModel: AccountsAwareAddTokenViewModel)
        case getToken(viewModel: AccountsAwareGetTokenViewModel)

        var id: String {
            switch self {
            case .accountSelector:
                "accountSelector"
            case .networkSelector:
                "networkSelector"
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

            case .networkSelector(_, let context):
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

            case .networkSelector(_, let context):
                return context != .fromAddToken

            case .addToken:
                return true

            case .getToken:
                return true
            }
        }

        // MARK: - Equatable

        static func == (
            lhs: AccountsAwareAddTokenFlowViewModel.ViewState,
            rhs: AccountsAwareAddTokenFlowViewModel.ViewState
        ) -> Bool {
            switch (lhs, rhs) {
            case (.accountSelector, .accountSelector):
                return true
            case (.networkSelector, .networkSelector):
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
