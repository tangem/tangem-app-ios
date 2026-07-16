//
//  AddTokenConfirmViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import Combine
import TangemUI
import TangemAssets
import TangemAccounts
import TangemLocalization

@MainActor
final class AddTokenConfirmViewModel: ObservableObject, Identifiable {
    // MARK: - Published

    @Published private(set) var isSaving: Bool = false
    @Published private(set) var isTokenAlreadyAdded: Bool = false
    @Published private(set) var walletIcon: ImageValue?

    // MARK: - Token Display

    let tokenName: String
    let tokenSubtitle: String
    let tokenIconInfo: TokenIconInfo

    // MARK: - Row Data

    let accountRowData: AccountRowData
    let networkRowData: NetworkRowData
    let isAccountSelectionAvailable: Bool
    let isNetworkSelectionAvailable: Bool

    // MARK: - UI

    var confirmButtonContent: TangemButton.Content {
        let providedIcon = CommonTangemIconProvider(config: accountSelectorCell.userWalletModel.config).getMainButtonIcon()
        let text = AttributedString(Localization.commonConfirm)

        if let providedIcon {
            return .combined(
                text: text,
                icon: providedIcon.imageType,
                iconPosition: .right
            )
        } else {
            return .text(text)
        }
    }

    // MARK: - Private

    private let tokenItem: TokenItem
    private let accountSelectorCell: AccountSelectorCellModel
    private let analyticsLogger: AddTokenAnalyticsLogger
    private let isTokenAddedPredicate: (TokenItem, any CryptoAccountModel) -> Bool
    private let onAccountTapped: () -> Void
    private let onNetworkTapped: () -> Void
    private let onConfirmTapped: (Result<TokenItem, Error>) -> Void
    private let walletImageProvider: WalletImageProviding?
    private var bag = Set<AnyCancellable>()
    private var saveTask: Task<Void, Never>?

    private var account: any CryptoAccountModel { accountSelectorCell.cryptoAccountModel }

    // MARK: - Init

    init(
        tokenItem: TokenItem,
        accountSelectorCell: AccountSelectorCellModel,
        userWalletModels: [any UserWalletModel],
        tokenItemIconInfoBuilder: TokenIconInfoBuilder,
        isAccountSelectionAvailable: Bool,
        isNetworkSelectionAvailable: Bool,
        analyticsLogger: AddTokenAnalyticsLogger,
        isTokenAdded: @escaping (TokenItem, any CryptoAccountModel) -> Bool,
        onAccountTapped: @escaping () -> Void,
        onNetworkTapped: @escaping () -> Void,
        onConfirmTapped: @escaping (Result<TokenItem, Error>) -> Void
    ) {
        self.tokenItem = tokenItem
        self.accountSelectorCell = accountSelectorCell
        self.isAccountSelectionAvailable = isAccountSelectionAvailable
        self.isNetworkSelectionAvailable = isNetworkSelectionAvailable
        self.analyticsLogger = analyticsLogger
        isTokenAddedPredicate = isTokenAdded
        self.onAccountTapped = onAccountTapped
        self.onNetworkTapped = onNetworkTapped
        self.onConfirmTapped = onConfirmTapped

        tokenName = tokenItem.name
        tokenSubtitle = tokenItem.currencySymbol

        tokenIconInfo = tokenItemIconInfoBuilder.build(
            for: tokenItem.amountType,
            in: tokenItem.blockchain,
            isCustom: tokenItem.token?.isCustom ?? false
        )

        let hasMultipleAccounts = userWalletModels.contains { wm in
            wm.accountModelsManager.accountModels.cryptoAccounts().hasMultipleAccounts
        }
        accountRowData = Self.makeAccountRowData(
            accountSelectorCell: accountSelectorCell,
            displayWallet: !hasMultipleAccounts
        )
        if case .wallet(let walletItem) = accountSelectorCell {
            walletImageProvider = walletItem.walletImageProvider
        } else {
            walletImageProvider = nil
        }

        networkRowData = NetworkRowData(
            iconImageAsset: NetworkImageProvider().provide(by: tokenItem.blockchain, filled: true),
            name: tokenItem.blockchain.displayName
        )

        bind()
    }

    deinit {
        saveTask?.cancel()
    }

    // MARK: - Public

    func handleAccountTap() {
        guard isAccountSelectionAvailable else { return }
        onAccountTapped()
    }

    func handleNetworkTap() {
        guard isNetworkSelectionAvailable else { return }
        onNetworkTapped()
    }

    func loadWalletImage() async {
        guard let walletImageProvider else { return }
        walletIcon = await walletImageProvider.loadSmallImage()
    }

    func handleConfirmTap() {
        guard !isSaving else { return }

        analyticsLogger.logAddTokenButtonTapped()
        isSaving = true
        saveTask = Task { [weak self] in
            await self?.performAddToken()
        }
    }

    // MARK: - Private

    private func bind() {
        account.userTokensManager
            .userTokensPublisher
            .compactMap { [weak self] _ in self }
            .map { vm in
                vm.isTokenAddedPredicate(vm.tokenItem, vm.account)
            }
            .assign(to: &$isTokenAlreadyAdded)
    }

    private func performAddToken() async {
        let tokenItem = tokenItem
        let userTokensManager = account.userTokensManager

        do {
            try userTokensManager.addTokenItemHardwarePrecondition(tokenItem)
            let addedToken = try await Self.performTokenUpdate(
                tokenItem: tokenItem,
                userTokensManager: userTokensManager
            )
            isSaving = false
            saveTask = nil
            analyticsLogger.logTokenAdded(tokenItem: tokenItem, isMainAccount: account.isMainAccount)
            onConfirmTapped(.success(addedToken))
        } catch {
            isSaving = false
            saveTask = nil
            if !error.isCancellationError {
                onConfirmTapped(.failure(error))
            }
        }
    }

    private static func performTokenUpdate(
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
                        continuation.resume(throwing: AddTokenError.tokenNotReturned)
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private static func makeAccountRowData(
        accountSelectorCell: AccountSelectorCellModel,
        displayWallet: Bool
    ) -> AccountRowData {
        if displayWallet {
            return AccountRowData(
                kind: .wallet,
                label: Localization.wcCommonWallet,
                name: accountSelectorCell.userWalletModel.name
            )
        }
        let account = accountSelectorCell.cryptoAccountModel
        return AccountRowData(
            kind: .account(iconData: AccountModelUtils.UI.iconViewData(accountModel: account)),
            label: Localization.accountDetailsTitle,
            name: account.name
        )
    }
}

// MARK: - Data Types

extension AddTokenConfirmViewModel {
    enum AccountRowKind: Equatable {
        case account(iconData: AccountIconView.ViewData)
        case wallet
    }

    struct AccountRowData: Equatable {
        let kind: AccountRowKind
        let label: String
        let name: String
    }

    struct NetworkRowData: Equatable {
        let iconImageAsset: ImageType
        let name: String
    }

    enum AddTokenError: LocalizedError {
        case tokenNotReturned

        var errorDescription: String? {
            switch self {
            case .tokenNotReturned:
                return Localization.commonSomethingWentWrong
            }
        }
    }
}

// MARK: - Equatable

extension AddTokenConfirmViewModel: Equatable {
    nonisolated static func == (lhs: AddTokenConfirmViewModel, rhs: AddTokenConfirmViewModel) -> Bool {
        lhs === rhs
    }
}
