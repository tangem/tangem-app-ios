//
//  UserSettingsAccountsViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemUI
import Combine
import CombineExt
import TangemLocalization
import TangemFoundation
import TangemAccounts
import TangemMacro

final class UserSettingsAccountsViewModel: ObservableObject {
    // MARK: - Published State

    @Published var accountRows: [AccountRow] = []
    @Published private(set) var addNewAccountButton: AddListItemButton.ViewData?
    @Published private(set) var archivedAccountsButton: ArchivedAccountsButtonViewData?

    // MARK: - Dependencies

    private let accountModelsManager: AccountModelsManager
    private let accountsReorderer: UserSettingsAccountsReorderer
    private let userWalletConfig: UserWalletConfig
    private weak var coordinator: UserSettingsAccountsRoutable?

    private var cachedAccountRows: [AnyHashable: AccountRow] = [:]
    private var bag = Set<AnyCancellable>()

    // MARK: - Init

    init(
        accountModelsManager: AccountModelsManager,
        userWalletConfig: UserWalletConfig,
        coordinator: UserSettingsAccountsRoutable?
    ) {
        self.accountModelsManager = accountModelsManager
        self.userWalletConfig = userWalletConfig
        self.coordinator = coordinator
        accountsReorderer = UserSettingsAccountsReorderer(
            accountModelsReorderer: accountModelsManager,
            debounceInterval: Constants.accountsReorderingDebounceInterval
        )

        bind()
    }

    // MARK: - Public

    var moreThatOneActiveAccount: Bool {
        accountRows.count > 1
    }

    func handleAccountOperationResult(_ result: AccountOperationResult) {
        guard let names = result.redistributedAccountNames else {
            return
        }

        coordinator?.handleAccountsRedistribution(
            sourceAccountName: names.source,
            targetAccountName: names.target
        )
    }

    func handleCreatedAccount(_ account: (any CryptoAccountModel)?) {
        guard let account else {
            return
        }

        coordinator?.openManageTokens(
            accountModelsManager: accountModelsManager,
            cryptoAccountModel: account,
            userWalletConfig: userWalletConfig
        )
    }

    // MARK: - Binding

    private func bind() {
        bindAccountRows()
        bindArchivedAccountsButton()
        bindAddNewAccountButton()
        bindPendingReorder()
    }

    private func bindAccountRows() {
        BaseAccountModelsAggregator(.crypto, .joint, .collectibles(.shown))
            .modelsPublisher(from: accountModelsManager)
            .combineLatest(accountModelsManager.accountsOrderPublisher)
            .map { accounts, accountsOrder in
                AccountModelUtils.ordered(accounts, by: accountsOrder) { account in
                    account.id.toPersistentIdentifier().toAnyHashable()
                }
            }
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, accounts in
                viewModel.updateAccountRows(from: accounts)
            }
            .store(in: &bag)
    }

    private func bindArchivedAccountsButton() {
        accountModelsManager
            .hasArchivedCryptoAccountsPublisher
            .withWeakCaptureOf(self)
            .map { viewModel, hasArchivedAccounts in
                guard hasArchivedAccounts else {
                    return nil
                }

                return ArchivedAccountsButtonViewData(text: Localization.accountArchivedAccounts) { [weak viewModel] in
                    viewModel?.onTapArchivedAccounts()
                }
            }
            .receiveOnMain()
            .assign(to: \.archivedAccountsButton, on: self, ownership: .weak)
            .store(in: &bag)
    }

    private func bindAddNewAccountButton() {
        accountModelsManager
            .accountModelsPublisher
            .withWeakCaptureOf(self)
            .receiveOnMain()
            .map { viewModel, accountModels in
                viewModel.makeAddNewAccountButtonViewData(from: accountModels)
            }
            .receiveOnMain()
            .assign(to: \.addNewAccountButton, on: self, ownership: .weak)
            .store(in: &bag)
    }

    private func bindPendingReorder() {
        $accountRows
            .removeDuplicates { lhs, rhs in
                lhs.map(\.id) == rhs.map(\.id)
            }
            .pairwise()
            .withWeakCaptureOf(self)
            .sink { viewModel, input in
                let (oldRows, newRows) = input
                viewModel.accountsReorderer.schedulePendingReorderIfNeeded(
                    oldRows: oldRows,
                    newRows: newRows,
                    persistentIdentifierProvider: Self.extractPersistentIdentifier(from:)
                )
            }
            .store(in: &bag)
    }

    // MARK: - View Data Factory

    private func makeAddNewAccountButtonViewData(from accountModels: [AccountModel]) -> AddListItemButton.ViewData {
        let isCryptoLimitReached = AccountModelUtils.isAccountsLimitReached(for: .crypto, in: accountModels)
        let canAddJointAccount = FeatureProvider.isAvailable(.jointAccounts)
            && !AccountModelUtils.isAccountsLimitReached(for: .joint, in: accountModels)
        let isLimitReached = isCryptoLimitReached && !canAddJointAccount
        let buttonState = makeAddNewAccountButtonState(isLimitReached: isLimitReached)

        return AddListItemButton.ViewData(
            text: Localization.accountFormCreateButton,
            state: buttonState
        )
    }

    private func makeAddNewAccountButtonState(isLimitReached: Bool) -> AddListItemButton.State {
        if isLimitReached {
            .disabled(action: { [weak self] in
                self?.handleAccountLimitReached()
            })
        } else {
            .enabled(action: { [weak self] in
                self?.onTapNewAccount()
            })
        }
    }

    // MARK: - Actions

    private func onTapAccount(account: any BaseAccountModel) {
        Analytics.log(.walletSettingsButtonOpenExistingAccount)
        coordinator?.openAccountDetails(
            account: account,
            accountModelsManager: accountModelsManager,
            userWalletConfig: userWalletConfig
        )
    }

    private func onTapArchivedAccounts() {
        Analytics.log(.walletSettingsButtonArchivedAccounts)
        coordinator?.openArchivedAccounts(accountModelsManager: accountModelsManager)
    }

    private func onTapNewAccount() {
        guard FeatureProvider.isAvailable(.jointAccounts) else {
            // With the selector the event is logged once the crypto account is picked, see `AddAccountTypeSelectorViewModel`
            Analytics.log(event: .walletSettingsButtonAddAccount, params: [
                .productType: userWalletConfig.productType.rawValue,
                .source: Analytics.ParameterValue.settings.rawValue,
            ])
            coordinator?.addNewAccount()
            return
        }

        coordinator?.openAddAccountTypeSelector(userWalletConfig: userWalletConfig)
    }

    private func handleAccountLimitReached() {
        coordinator?.handleAccountsLimitReached()
    }

    // MARK: - Utilities

    private func updateAccountRows(from accounts: [any BaseAccountModel]) {
        let resolver = AccountRowResolver(viewModel: self)

        accountRows = accounts.map { $0.resolve(using: resolver) }
        cachedAccountRows = accountRows.keyedFirst(by: \.id)
    }

    private func makeRegularAccountRow(account: any BaseAccountModel, hasDetails: Bool) -> AccountRow {
        makeAccountRow(account: account, reusing: \.isRegular) {
            let viewModel = AccountRowButtonViewModel(
                accountModel: account,
                availability: hasDetails ? .available : .unavailable()
            ) { [weak self] in
                self?.onTapAccount(account: account)
            }

            return .regular(viewModel, hasDetails: hasDetails)
        }
    }

    private func makePausedAccountRow(jointAccount: any JointAccountModel) -> AccountRow {
        makeAccountRow(account: jointAccount, reusing: \.isPaused) {
            let viewModel = PausedJointAccountItemViewModel(jointAccount: jointAccount) { [weak self] in
                self?.coordinator?.showPausedJointAccountAlert()
            }

            return .paused(viewModel)
        }
    }

    private func makeAccountRow(
        account: any BaseAccountModel,
        reusing isReusable: (AccountRow.Content) -> Bool,
        makeContent: () -> AccountRow.Content
    ) -> AccountRow {
        if let cached = cachedAccountRows[account.id.toAnyHashable()], isReusable(cached.content) {
            return cached
        }

        return AccountRow(content: makeContent(), accountModel: account)
    }

    private static func extractPersistentIdentifier(
        from accountRow: AccountRow
    ) -> any AccountModelPersistentIdentifierConvertible {
        accountRow.accountModel.id
    }
}

// MARK: - Auxiliary types

extension UserSettingsAccountsViewModel {
    struct ArchivedAccountsButtonViewData: Identifiable {
        let text: String
        let action: () -> Void

        var id: String {
            text
        }
    }

    /// An opaque wrapper to prevent an exposure of the `BaseAccountModel` associated with the row.
    struct AccountRow: Identifiable {
        let id: AnyHashable
        let content: Content
        fileprivate let accountModel: any BaseAccountModel

        fileprivate init(
            content: Content,
            accountModel: any BaseAccountModel
        ) {
            id = accountModel.id.toAnyHashable()
            self.content = content
            self.accountModel = accountModel
        }
    }
}

extension UserSettingsAccountsViewModel.AccountRow {
    @CaseFlagable
    enum Content {
        case regular(AccountRowButtonViewModel, hasDetails: Bool)
        case paused(PausedJointAccountItemViewModel)
    }
}

// MARK: - AccountRowResolver

private extension UserSettingsAccountsViewModel {
    struct AccountRowResolver: AccountModelResolving {
        let viewModel: UserSettingsAccountsViewModel

        func resolve(accountModel: any StandardCryptoAccountModel) -> AccountRow {
            viewModel.makeRegularAccountRow(account: accountModel, hasDetails: true)
        }

        func resolve(accountModel: any JointAccountModel) -> AccountRow {
            if accountModel.jointAccountStatusProvider.status.isUntrusted {
                return viewModel.makePausedAccountRow(jointAccount: accountModel)
            }

            return viewModel.makeRegularAccountRow(account: accountModel, hasDetails: true)
        }

        func resolve(accountModel: any TangemPayAccountModel) -> AccountRow {
            viewModel.makeRegularAccountRow(account: accountModel, hasDetails: true)
        }

        func resolve(accountModel: any PolymarketAccountModel) -> AccountRow {
            viewModel.makeRegularAccountRow(account: accountModel, hasDetails: true)
        }

        func resolve(accountModel: any CollectiblesAccountModel) -> AccountRow {
            viewModel.makeRegularAccountRow(account: accountModel, hasDetails: false)
        }
    }
}

// MARK: - Constants

private extension UserSettingsAccountsViewModel {
    enum Constants {
        static let accountsReorderingDebounceInterval = 1.0
    }
}
