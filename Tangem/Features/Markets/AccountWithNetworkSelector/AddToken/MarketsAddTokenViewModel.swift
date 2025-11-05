//
//  MarketsAddTokenViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemUI
import Combine
import TangemAssets
import TangemAccounts

// MARK: - Selector Data Provider Protocols

protocol MarketsAddTokenAccountWalletSelectorDataProvider {
    var displayTitle: String { get }
    var trailingContent: MarketsAddTokenViewModel.AccountWalletTrailingContent { get }
    var isSelectionAvailable: Bool { get }
    var handleSelection: () -> Void { get }
}

protocol MarketsAddTokenNetworkSelectorDataProvider {
    var displayTitle: String { get }
    var trailingContent: (imageAsset: ImageType, name: String) { get }
    var isSelectionAvailable: Bool { get }
    var handleSelection: () -> Void { get }
}

// MARK: - ViewModel

@MainActor
final class MarketsAddTokenViewModel: ObservableObject, FloatingSheetContentViewModel {
    // MARK: - Published Properties

    @Published private(set) var accountWalletSelectorState: AccountWalletSelectorState
    @Published private(set) var networkSelectorState: NetworkSelectorState

    // MARK: - Immutable Properties

    let tokenItemViewState: EntitySummaryView.ViewState

    // MARK: - Private Properties

    private let tokenItem: TokenItem
    private let accountWalletDataProvider: MarketsAddTokenAccountWalletSelectorDataProvider
    private let networkDataProvider: MarketsAddTokenNetworkSelectorDataProvider

    // MARK: - Initialization

    init(
        tokenItem: TokenItem,
        tokenItemIconInfoBuilder: TokenIconInfoBuilder,
        accountWalletDataProvider: MarketsAddTokenAccountWalletSelectorDataProvider,
        networkDataProvider: MarketsAddTokenNetworkSelectorDataProvider
    ) {
        self.tokenItem = tokenItem
        self.accountWalletDataProvider = accountWalletDataProvider
        self.networkDataProvider = networkDataProvider

        // Build token header
        let tokenIconInfo = tokenItemIconInfoBuilder.build(
            for: tokenItem.amountType,
            in: tokenItem.blockchain,
            isCustom: tokenItem.token?.isCustom ?? false
        )

        tokenItemViewState = .content(
            EntitySummaryView.ViewState.ContentState(
                imageLocation: .customView(
                    EntitySummaryView.ViewState.ContentState.ImageLocation.CustomViewWrapper(
                        content: {
                            TokenIcon(
                                tokenIconInfo: tokenIconInfo,
                                size: .init(bothDimensions: 36)
                            )
                        }
                    )
                ),
                title: tokenItem.name,
                subtitle: tokenItem.currencySymbol,
                titleInfoConfig: nil
            )
        )

        // Initialize selector states
        accountWalletSelectorState = AccountWalletSelectorState(
            label: accountWalletDataProvider.displayTitle,
            trailingContent: accountWalletDataProvider.trailingContent,
            isSelectionAvailable: accountWalletDataProvider.isSelectionAvailable
        )

        networkSelectorState = NetworkSelectorState(
            label: networkDataProvider.displayTitle,
            trailingContent: networkDataProvider.trailingContent,
            isSelectionAvailable: networkDataProvider.isSelectionAvailable
        )
    }

    // MARK: - Public Methods

    func handleViewEvent(_ event: ViewEvent) {
        switch event {
        case .accountWalletSelectorTapped:
            accountWalletDataProvider.handleSelection()

        case .networkSelectorTapped:
            networkDataProvider.handleSelection()

        case .addTokenButtonTapped:
            // [REDACTED_TODO_COMMENT]
            break
        }
    }
}

// MARK: - ViewEvent

extension MarketsAddTokenViewModel {
    enum ViewEvent {
        case accountWalletSelectorTapped
        case networkSelectorTapped
        case addTokenButtonTapped
    }
}

// MARK: - Account/Wallet Selector State

extension MarketsAddTokenViewModel {
    struct AccountWalletSelectorState {
        let label: String
        let trailingContent: AccountWalletTrailingContent
        let isSelectionAvailable: Bool
    }

    enum AccountWalletTrailingContent: Equatable {
        case walletName(String)
        case account(AccountIconView.ViewData, name: String)
    }
}

// MARK: - Network Selector State

extension MarketsAddTokenViewModel {
    struct NetworkSelectorState {
        let label: String
        let trailingContent: (imageAsset: ImageType, name: String)
        let isSelectionAvailable: Bool
    }
}
