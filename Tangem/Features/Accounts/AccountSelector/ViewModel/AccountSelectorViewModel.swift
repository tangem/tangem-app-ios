//
//  AccountSelectorViewModel.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemUI
import TangemAccounts
import SwiftUI
import TangemLocalization

@MainActor
final class AccountSelectorViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published private(set) var displayMode: AccountSelectorDisplayMode = .wallets
    @Published private(set) var lockedWalletItems: [AccountSelectorWalletItem] = []
    @Published private(set) var walletItems: [AccountSelectorWalletItem] = []
    @Published private(set) var accountsSections: [AccountSelectorMultipleAccountsItem] = []
    @Published private(set) var selectedItem: (any BaseAccountModel)?
    @Published private(set) var state: AccountSelectorViewState = .init(navigationBarTitle: "")

    // MARK: - Private Properties

    private let userWalletModels: [any UserWalletModel]
    private let cryptoAccountModelsFilter: (any CryptoAccountModel) -> Bool
    private let availabilityProvider: (any CryptoAccountModel) -> AccountAvailability
    private let onSelect: (AccountSelectorCellModel) -> Void
    private var bag = Set<AnyCancellable>()

    // MARK: - Initialization

    init(
        selectedItem: (any BaseAccountModel)? = nil,
        userWalletModels: [any UserWalletModel],
        cryptoAccountModelsFilter: @escaping (any CryptoAccountModel) -> Bool = { _ in true },
        availabilityProvider: @escaping (any CryptoAccountModel) -> AccountAvailability = { _ in .available },
        onSelect: @escaping (AccountSelectorCellModel) -> Void
    ) {
        self.selectedItem = selectedItem
        self.userWalletModels = userWalletModels
        self.cryptoAccountModelsFilter = cryptoAccountModelsFilter
        self.availabilityProvider = availabilityProvider
        self.onSelect = onSelect

        let hasMultipleAccounts = userWalletModels.contains { userWalletModel in
            userWalletModel.accountModelsManager.accountModels.cryptoAccounts().hasMultipleAccounts
        }

        displayMode = hasMultipleAccounts ? .accounts : .wallets

        switch displayMode {
        case .accounts:
            state.navigationBarTitle = Localization.commonChooseAccount
        case .wallets:
            state.navigationBarTitle = Localization.commonChooseWallet
        }

        bind()
    }

    convenience init(
        selectedItem: (any BaseAccountModel)? = nil,
        userWalletModel: any UserWalletModel,
        cryptoAccountModelsFilter: @escaping (any CryptoAccountModel) -> Bool = { _ in true },
        availabilityProvider: @escaping (any CryptoAccountModel) -> AccountAvailability = { _ in .available },
        onSelect: @escaping (AccountSelectorCellModel) -> Void
    ) {
        self.init(
            selectedItem: selectedItem,
            userWalletModels: [userWalletModel],
            cryptoAccountModelsFilter: cryptoAccountModelsFilter,
            availabilityProvider: availabilityProvider,
            onSelect: onSelect
        )
    }

    // MARK: - Public Methods

    func handleViewAction(_ action: ViewAction) {
        switch action {
        case .selectItem(let item):
            switch item {
            case .wallet(let model):
                if case .active = model.wallet {
                    selectedItem = model.mainAccount
                    onSelect(.wallet(model))
                }
            case .account(let model):
                selectedItem = model.domainModel
                onSelect(.account(model))
            }
        }
    }

    func isCellSelected(for cell: AccountSelectorCellModel) -> Bool {
        switch cell {
        case .wallet(let model):
            if case .active = model.wallet {
                return selectedItem?.id.toAnyHashable() == model.mainAccount.id.toAnyHashable()
            }
        case .account(let model):
            guard model.availability == .available else { return false }
            return selectedItem?.id.toAnyHashable() == model.domainModel.id.toAnyHashable()
        }

        return false
    }

    // MARK: - Private Methods

    private func bind() {
        userWalletModels
            .forEach { userWallet in
                userWallet.accountModelsManager.accountModelsPublisher
                    .receiveOnMain()
                    .withWeakCaptureOf(self)
                    .sink { viewModel, accountModels in

                        viewModel.walletItems.removeAll(where: { $0.id == userWallet.userWalletId.stringValue })
                        viewModel.accountsSections.removeAll(where: { $0.walletId == userWallet.userWalletId.stringValue })

                        let (wallets, accountsSections) = viewModel.makeUpdatedSelectorData(
                            userWallet: userWallet, from: accountModels
                        )

                        if userWallet.isUserWalletLocked {
                            viewModel.lockedWalletItems.append(contentsOf: wallets)
                        } else {
                            viewModel.walletItems.append(contentsOf: wallets)
                        }

                        viewModel.accountsSections.append(contentsOf: accountsSections)
                    }
                    .store(in: &bag)
            }
    }

    private func makeUpdatedSelectorData(
        userWallet: any UserWalletModel,
        from accountModels: [AccountModel]
    ) -> (wallets: [AccountSelectorWalletItem], accountsSections: [AccountSelectorMultipleAccountsItem]) {
        var wallets = [AccountSelectorWalletItem]()
        var accountSections = [AccountSelectorMultipleAccountsItem]()

        accountModels.forEach { accountModel in
            switch displayMode {
            case .wallets:
                guard let walletItem = makeWalletSectionItem(from: accountModel, and: userWallet) else { return }
                wallets.append(walletItem)
            case .accounts:
                guard let accountSectionItem = makeAccountSectionItem(from: accountModel, and: userWallet) else { return }
                accountSections.append(accountSectionItem)
            }
        }

        return (wallets, accountSections)
    }

    private func makeWalletSectionItem(
        from accountModel: AccountModel,
        and userWallet: UserWalletModel
    ) -> AccountSelectorWalletItem? {
        switch accountModel {
        case .standard(.single(let cryptoAccountModel)):
            guard cryptoAccountModelsFilter(cryptoAccountModel) else { return nil }

            return .init(
                userWallet: userWallet,
                cryptoAccountModel: cryptoAccountModel,
                isLocked: userWallet.isUserWalletLocked
            )

        case .standard(.multiple(let cryptoAccountModels)):
            guard let cryptoAccountModel = cryptoAccountModels.first(where: { $0.isMainAccount }) else {
                preconditionFailure("Active wallet must have at least one crypto account")
            }

            guard cryptoAccountModelsFilter(cryptoAccountModel) else { return nil }

            return .init(
                userWallet: userWallet,
                cryptoAccountModel: cryptoAccountModel,
                isLocked: userWallet.isUserWalletLocked
            )
        }
    }

    private func makeAccountSectionItem(
        from accountModel: AccountModel,
        and userWallet: UserWalletModel
    ) -> AccountSelectorMultipleAccountsItem? {
        switch accountModel {
        case .standard(.single(let cryptoAccountModel)):
            guard cryptoAccountModelsFilter(cryptoAccountModel) else { return nil }

            return AccountSelectorMultipleAccountsItem(
                userWallet: userWallet,
                accounts: [
                    AccountSelectorAccountItem(
                        account: cryptoAccountModel,
                        userWalletModel: userWallet,
                        availability: .available
                    ),
                ],
                onSelect: { [weak self] item in
                    self?.handleViewAction(.selectItem(.account(item)))
                }
            )

        case .standard(.multiple(let cryptoAccountModels)):
            let filteredCryptoAccountModels = cryptoAccountModels.filter(cryptoAccountModelsFilter)

            guard filteredCryptoAccountModels.isNotEmpty else { return nil }

            return AccountSelectorMultipleAccountsItem(
                userWallet: userWallet,
                accounts: filteredCryptoAccountModels.map {
                    AccountSelectorAccountItem(account: $0, userWalletModel: userWallet, availability: availabilityProvider($0))
                },
                onSelect: { [weak self] item in
                    self?.handleViewAction(.selectItem(.account(item)))
                }
            )
        }
    }
}

enum AccountAvailability: Equatable {
    case available
    case unavailable(reason: String? = nil)

    var isBalanceVisible: Bool {
        switch self {
        case .available:
            true
        case .unavailable(let reason):
            reason == nil
        }
    }
}

extension AccountSelectorViewModel {
    enum ViewAction {
        case selectItem(AccountSelectorCellModel)
    }
}

extension AccountSelectorViewModel: FloatingSheetContentViewModel {}
