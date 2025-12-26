//
//  AccountsAwareAddTokenViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemUI
import Combine
import TangemAssets
import TangemAccounts
import SwiftUI
import TangemLocalization
import struct TangemUIUtils.AlertBinder

// MARK: - Selector Data Provider Protocols

protocol AccountsAwareAddTokenAccountWalletSelectorDataProvider {
    var displayTitle: String { get }
    var trailingContent: AccountsAwareAddTokenViewModel.AccountWalletTrailingContent { get }
    var isSelectionAvailable: Bool { get }
    var handleSelection: () -> Void { get }
}

protocol AccountsAwareAddTokenNetworkSelectorDataProvider {
    var displayTitle: String { get }
    var trailingContent: (imageAsset: ImageType, name: String) { get }
    var isSelectionAvailable: Bool { get }
    var handleSelection: () -> Void { get }
}

// MARK: - ViewModel

@MainActor
final class AccountsAwareAddTokenViewModel: ObservableObject, FloatingSheetContentViewModel {
    // MARK: - Published Properties

    @Published private(set) var accountWalletSelectorState: AccountWalletSelectorState
    @Published private(set) var networkSelectorState: NetworkSelectorState
    @Published private(set) var isSaving: Bool = false
    @Published private(set) var needsCardDerivation: Bool = false

    // MARK: - Immutable Properties

    let tokenItemViewState: EntitySummaryView.ViewState

    // MARK: - Private Properties

    private let tokenItem: TokenItem
    private let account: any CryptoAccountModel
    private let accountWalletDataProvider: AccountsAwareAddTokenAccountWalletSelectorDataProvider
    private let networkDataProvider: AccountsAwareAddTokenNetworkSelectorDataProvider
    private let analyticsLogger: AddTokenAnalyticsLogger
    private let onAddTokenTapped: (Result<TokenItem, Error>) -> Void
    private var bag = Set<AnyCancellable>()

    // MARK: - Initialization

    init(
        tokenItem: TokenItem,
        account: any CryptoAccountModel,
        tokenItemIconInfoBuilder: TokenIconInfoBuilder,
        accountWalletDataProvider: AccountsAwareAddTokenAccountWalletSelectorDataProvider,
        networkDataProvider: AccountsAwareAddTokenNetworkSelectorDataProvider,
        analyticsLogger: AddTokenAnalyticsLogger,
        onAddTokenTapped: @escaping (Result<TokenItem, Error>) -> Void
    ) {
        self.tokenItem = tokenItem
        self.account = account
        self.accountWalletDataProvider = accountWalletDataProvider
        self.networkDataProvider = networkDataProvider
        self.analyticsLogger = analyticsLogger
        self.onAddTokenTapped = onAddTokenTapped

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

        bind()
    }

    // MARK: - Public Methods

    func handleViewEvent(_ event: ViewEvent) {
        switch event {
        case .accountWalletSelectorTapped:
            accountWalletDataProvider.handleSelection()

        case .networkSelectorTapped:
            networkDataProvider.handleSelection()

        case .addTokenButtonTapped:
            addToken()
        }
    }

    // MARK: - Private Methods

    private func bind() {
        account.userTokensManager
            .userTokensPublisher
            .map { [weak self] _ in
                guard let self else { return false }

                return account.userTokensManager.needsCardDerivation(
                    itemsToRemove: [],
                    itemsToAdd: [tokenItem]
                )
            }
            .assign(to: &$needsCardDerivation)
    }

    private func addToken() {
        guard !isSaving else { return }

        isSaving = true

        Task { [weak self] in
            await self?.performAddToken()
        }
    }

    private func performAddToken() async {
        let tokenItem = tokenItem
        let userTokensManager = account.userTokensManager

        do {
            let addedToken = try await performTokenUpdate(
                tokenItem: tokenItem,
                userTokensManager: userTokensManager
            )

            handleAddTokenSuccess(addedToken: addedToken)
        } catch {
            handleAddTokenFailure(error)
        }
    }

    private func performTokenUpdate(
        tokenItem: TokenItem,
        userTokensManager: UserTokensManager
    ) async throws -> TokenItem {
        try await withCheckedThrowingContinuation { continuation in
            userTokensManager.update(itemsToRemove: [], itemsToAdd: [tokenItem]) { result in
                switch result {
                case .success(let updatedItems):
                    if let addedToken = updatedItems.added.first {
                        continuation.resume(returning: addedToken)
                    } else {
                        continuation.resume(throwing: WalletModelCreationError.tokenNotReturned)
                    }

                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func handleAddTokenSuccess(addedToken: TokenItem) {
        isSaving = false
        sendAnalytics()
        onAddTokenTapped(.success(addedToken))
    }

    private func handleAddTokenFailure(_ error: Error) {
        isSaving = false
        if !error.isCancellationError {
            onAddTokenTapped(.failure(error))
        }
    }

    private func sendAnalytics() {
        analyticsLogger.logTokenAdded(tokenItem: tokenItem, isMainAccount: account.isMainAccount)
    }
}

// MARK: - ViewEvent

extension AccountsAwareAddTokenViewModel {
    enum ViewEvent {
        case accountWalletSelectorTapped
        case networkSelectorTapped
        case addTokenButtonTapped
    }
}

// MARK: - Account/Wallet Selector State

extension AccountsAwareAddTokenViewModel {
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

extension AccountsAwareAddTokenViewModel {
    struct NetworkSelectorState {
        let label: String
        let trailingContent: (imageAsset: ImageType, name: String)
        let isSelectionAvailable: Bool
    }
}

// MARK: - Errors

extension AccountsAwareAddTokenViewModel {
    enum WalletModelCreationError: LocalizedError {
        case tokenNotReturned

        var errorDescription: String? {
            switch self {
            case .tokenNotReturned:
                return Localization.commonSomethingWentWrong
            }
        }
    }
}
