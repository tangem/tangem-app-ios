//
//  AccountSelectorViewModel.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

@MainActor
final class AccountSelectorViewModel: ObservableObject {
    // MARK: - Dependencies

    @Injected(\.userWalletRepository) private var userWalletRepository: any UserWalletRepository

    // MARK: - Published Properties

    @Published private(set) var displayMode: AccountSelectorDisplayMode = .wallets
    @Published private(set) var lockedWalletItems: [AccountSelectorWalletItem] = []
    @Published private(set) var walletItems: [AccountSelectorWalletItem] = []
    @Published private(set) var accountsSections: [AccountSelectorMultipleAccountsItem] = []
    @Published private(set) var selectedAccount: AccountSelectorCellModel

    // MARK: - Private Properties

    private let onSelect: (AccountSelectorCellModel) -> Void
    private var bag = Set<AnyCancellable>()

    // MARK: - Initialization

    init(
        selectedAccount: AccountSelectorCellModel,
        onSelect: @escaping (AccountSelectorCellModel) -> Void
    ) {
        self.onSelect = onSelect
        self.selectedAccount = selectedAccount

        bind()
    }

    // MARK: - Public Methods

    func handleViewAction(_ action: ViewAction) {
        switch action {
        case .selectItem(let account):
            selectedAccount = account
            onSelect(account)
        }
    }

    func isCellSelected(for cell: AccountSelectorCellModel) -> Bool {
        selectedAccount == cell
    }

    // MARK: - Private Methods

    private func bind() {
        userWalletRepository.models
            .forEach { userWallet in

                guard !userWallet.isUserWalletLocked else {
                    lockedWalletItems.append(.init(userWallet: userWallet))
                    return
                }

                userWallet.accountModelsManager.accountModelsPublisher
                    .receive(on: DispatchQueue.main)
                    .withWeakCaptureOf(self)
                    .sink { viewModel, cryptoAccounts in
                        viewModel.setDisplayMode(for: cryptoAccounts)

                        viewModel.walletItems.removeAll(where: { $0.domainModel.userWalletId == userWallet.userWalletId })
                        viewModel.accountsSections.removeAll(where: { $0.walletId == userWallet.userWalletId.stringValue })

                        let (wallets, accountsSections) = viewModel.makeUpdatedSelectorData(userWallet: userWallet, from: cryptoAccounts)

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
