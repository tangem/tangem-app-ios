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

@MainActor
final class AccountSelectorViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published private(set) var displayMode: AccountSelectorDisplayMode = .wallets
    @Published private(set) var lockedWalletItems: [AccountSelectorWalletItem] = []
    @Published private(set) var walletItems: [AccountSelectorWalletItem] = []
    @Published private(set) var accountsSections: [AccountSelectorMultipleAccountsItem] = []
    @Published private(set) var selectedItem: AccountSelectorCellModel?

    // MARK: - Private Properties

    private let userWalletModels: [any UserWalletModel]
    private let onSelect: (any BaseAccountModel) -> Void
    private var bag = Set<AnyCancellable>()

    // MARK: - Initialization

    init(
        selectedItem: AccountSelectorCellModel? = nil,
        userWalletModels: [any UserWalletModel],
        onSelect: @escaping (any BaseAccountModel) -> Void
    ) {
        self.selectedItem = selectedItem
        self.userWalletModels = userWalletModels
        self.onSelect = onSelect

        bind()
    }

    convenience init(
        selectedItem: AccountSelectorCellModel? = nil,
        userWalletModel: any UserWalletModel,
        onSelect: @escaping (any BaseAccountModel) -> Void
    ) {
        self.init(selectedItem: selectedItem, userWalletModels: [userWalletModel], onSelect: onSelect)
    }

    // MARK: - Public Methods

    func handleViewAction(_ action: ViewAction) {
        switch action {
        case .selectItem(let item):
            selectedItem = item

            switch item {
            case .wallet(let model):
                if case .active(let walletModel) = model.wallet {
                    onSelect(walletModel.mainAccount)
                }
            case .account(let model):
                onSelect(model.domainModel)
            }
        }
    }

    func isCellSelected(for cell: AccountSelectorCellModel) -> Bool {
        selectedItem == cell
    }

    // MARK: - Private Methods

    private func bind() {
        userWalletModels
            .forEach { userWallet in

                guard !userWallet.isUserWalletLocked else {
                    lockedWalletItems.append(.init(userWallet: userWallet))
                    return
                }

                userWallet.accountModelsManager.accountModelsPublisher
                    .receiveOnMain()
                    .withWeakCaptureOf(self)
                    .sink { viewModel, cryptoAccounts in
                        viewModel.setDisplayMode(for: cryptoAccounts)

                        viewModel.walletItems.removeAll(where: { $0.domainModel.userWalletId == userWallet.userWalletId })
                        viewModel.accountsSections.removeAll(where: { $0.walletId == userWallet.userWalletId.stringValue })

                        let (wallets, accountsSections) = viewModel.makeUpdatedSelectorData(
                            userWallet: userWallet, from: cryptoAccounts
                        )

                        viewModel.walletItems.append(contentsOf: wallets)
                        viewModel.accountsSections.append(contentsOf: accountsSections)
                    }
                    .store(in: &bag)
            }
    }

    private func setDisplayMode(for accounts: [AccountModel]) {
        let multipleAccounts = accounts.filter { account in
            if case .standard(.multiple) = account {
                return true
            }

            return false
        }

        displayMode = multipleAccounts.isEmpty ? .wallets : .accounts
    }

    private func makeUpdatedSelectorData(
        userWallet: any UserWalletModel,
        from cryptoAccounts: [AccountModel]
    ) -> (wallets: [AccountSelectorWalletItem], accountsSections: [AccountSelectorMultipleAccountsItem]) {
        var wallets = [AccountSelectorWalletItem]()
        var accountSections = [AccountSelectorMultipleAccountsItem]()

        cryptoAccounts.forEach {
            switch displayMode {
            case .wallets:
                wallets.append(.init(userWallet: userWallet, account: $0))
            case .accounts:
                accountSections.append(.init(userWallet: userWallet, accountModel: $0))
            }
        }

        return (wallets, accountSections)
    }
}

extension AccountSelectorViewModel {
    enum ViewAction {
        case selectItem(AccountSelectorCellModel)
    }
}

extension AccountSelectorViewModel: FloatingSheetContentViewModel {}
