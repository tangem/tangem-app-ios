//
//  AccountSelectorViewModel.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import TangemUIUtils

@MainActor
final class AccountSelectorViewModel: ObservableObject {
    // MARK: - Dependencies

    @Injected(\.userWalletRepository) private var userWalletRepository: any UserWalletRepository

    // MARK: - Published Properties

    @Published private(set) var displayMode: AccountSelectorDisplayMode = .wallets
    @Published private(set) var lockedWalletItems: [AccountSelectorWalletItem] = []
    @Published private(set) var walletItems: [AccountSelectorWalletItem] = []
    @Published private(set) var accountSections: [AccountSelectorMultipleAccountsItem] = []
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

    func checkItemSelection(for cell: AccountSelectorCellModel) -> Bool {
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
                        let standardAccounts = viewModel.fetchStandardAccounts(from: cryptoAccounts)

                        viewModel.setDisplayMode(for: standardAccounts)

                        standardAccounts.forEach {
                            viewModel.appendAccountModel(userWallet: userWallet, standardAccount: $0)
                        }
                    }
                    .store(in: &bag)
            }
    }

    private func setDisplayMode(for standardAccounts: [CryptoAccounts]) {
        if standardAccounts.contains(where: { standardAccount in
            if case .multiple = standardAccount {
                return true
            }

            return false
        }) {
            displayMode = .sections
        }
    }

    private func fetchStandardAccounts(from cryptoAccounts: [AccountModel]) -> [CryptoAccounts] {
        cryptoAccounts.compactMap { item in
            if case .standard(let standardAccount) = item {
                return standardAccount
            }

            return nil
        }
    }

    private func appendAccountModel(userWallet: any UserWalletModel, standardAccount: CryptoAccounts) {
        switch standardAccount {
        case .single(let singleAccount):
            switch displayMode {
            case .wallets:
                walletItems.append(.init(userWallet: userWallet, account: singleAccount))
            case .sections:
                accountSections.append(.init(userWallet: userWallet, accounts: [singleAccount]))
            }
        case .multiple(let multipleAccounts):
            accountSections.append(.init(userWallet: userWallet, accounts: multipleAccounts))
        }
    }
}

extension AccountSelectorViewModel {
    enum ViewAction {
        case selectItem(AccountSelectorCellModel)
    }
}
