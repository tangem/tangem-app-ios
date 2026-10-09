//
//  AccountsFeedRouter.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation
import TangemLocalization
import TangemUIUtils

protocol AccountsFeedRoutable: AnyObject {
    func openAddAccount(candidates: [FeedAccountCandidate])
}

final class AccountsFeedRouter {
    @Injected(\.alertPresenter) private var alertPresenter: AlertPresenter

    private weak var navigation: (any FeedNavigation)?
    private weak var host: (any FeedHostRoutable)?
    private let widgetSheetPresenter: FeedWidgetSheetPresenter
    private weak var accountCreationWallet: UserWalletModel?
    private var accountFormCompletion: (() -> Void)?
    private let popToRootAction: Action<PopToRootOptions>

    init(context: FeedContext, host: FeedHostRoutable?, widgetSheetPresenter: FeedWidgetSheetPresenter) {
        navigation = context.navigation
        self.host = host
        self.widgetSheetPresenter = widgetSheetPresenter
        popToRootAction = context.popToRootAction
    }
}

// MARK: - AccountsFeedRoutable

extension AccountsFeedRouter: AccountsFeedRoutable {
    func openAddAccount(candidates: [FeedAccountCandidate]) {
        Task { @MainActor [weak self] in
            guard let self, let navigation, navigation.presented == nil,
                  !widgetSheetPresenter.isPresenting, let candidate = candidates.first else { return }

            if candidates.count == 1 {
                openAccountCreation(for: candidate)
                return
            }

            widgetSheetPresenter.presentWalletSelector(wallets: candidates.map(\.wallet)) { [weak self] wallet in
                guard let candidate = candidates.first(where: { $0.wallet.userWalletId == wallet.userWalletId }) else { return }

                self?.openAccountCreation(for: candidate)
            }
        }
    }
}

// MARK: - AddAccountTypeSelectorRoutable

extension AccountsFeedRouter: AddAccountTypeSelectorRoutable {
    func openCryptoAccountForm(accountModelsManager: any AccountModelsManager, userWalletConfig: UserWalletConfig) {
        Task { @MainActor in
            guard let navigation, navigation.presented == nil,
                  validateAccountLimit(for: .crypto, accountModelsManager: accountModelsManager) else { return }

            widgetSheetPresenter.dismissSelector { [weak self] in
                guard let self else { return }
                guard let navigation = self.navigation, navigation.presented == nil else { return }

                let viewModel = AccountFormViewModel(
                    flowType: .create(creator: CryptoAccountFormViewCreator(accountModelsManager: accountModelsManager)),
                    coordinator: self
                )
                navigation.present(.accountForm(viewModel), onDismiss: { [weak self] in
                    self?.accountFormDidDismiss()
                })
            }
        }
    }

    func openJointAccountManagement() {
        Task { @MainActor in
            guard let navigation, navigation.presented == nil, let accountCreationWallet,
                  validateAccountLimit(for: .joint, accountModelsManager: accountCreationWallet.accountModelsManager) else { return }

            widgetSheetPresenter.dismissSelector { [weak self] in
                guard let self else { return }
                guard let navigation = self.navigation, navigation.presented == nil else { return }

                let coordinator = JointAccountManagementCoordinator(
                    dismissAction: { [weak self] _ in
                        guard let navigation = self?.navigation, case .jointAccount = navigation.presented else { return }

                        navigation.dismissPresented()
                    },
                    popToRootAction: popToRootAction
                )
                coordinator.start(with: .creation(JointAccountCreationHelper(userWalletModel: accountCreationWallet)))
                navigation.present(.jointAccount(coordinator))
            }
        }
    }

    func dismissAddAccountTypeSelector() {
        Task { @MainActor in widgetSheetPresenter.dismissSelector() }
    }
}

// MARK: - AccountFormViewModelRoutable

extension AccountsFeedRouter: AccountFormViewModelRoutable {
    func closeAccountForm(outcome: AccountFormOutcome) {
        guard let navigation, case .accountForm = navigation.presented else { return }

        if case .completed(.crypto(let result, let createdAccount)) = outcome {
            accountFormCompletion = makeAccountFormCompletion(
                result: result,
                createdAccount: createdAccount,
                wallet: accountCreationWallet
            )
        }
        accountCreationWallet = nil
        navigation.dismissPresented()
    }
}

// MARK: - Widget sheets

@MainActor
private extension AccountsFeedRouter {
    func validateAccountLimit(for accountType: AccountType, accountModelsManager: any AccountModelsManager) -> Bool {
        guard !AccountModelUtils.isAccountsLimitReached(for: accountType, in: accountModelsManager.accountModels) else {
            alertPresenter.present(alert: AccountEditErrorAlertBuilder.makeAlert(for: .tooManyAccounts))
            return false
        }

        return true
    }

    func openAccountCreation(for candidate: FeedAccountCandidate) {
        guard let navigation, navigation.presented == nil, candidate.availability.isAvailable else { return }

        let wallet = candidate.wallet
        accountCreationWallet = wallet

        guard candidate.availability.joint else {
            openCryptoAccountForm(accountModelsManager: wallet.accountModelsManager, userWalletConfig: wallet.config)
            return
        }

        let viewModel = AddAccountTypeSelectorViewModel(
            accountModelsManager: wallet.accountModelsManager,
            userWalletConfig: wallet.config,
            coordinator: self,
            // The feed records the entry tap before presenting the selector.
            shouldLogAddAccountTap: false
        )
        widgetSheetPresenter.presentAccountTypeSelector(viewModel)
    }
}

// MARK: - Account form completion

private extension AccountsFeedRouter {
    func accountFormDidDismiss() {
        let completion = accountFormCompletion
        accountFormCompletion = nil
        completion?()
    }

    func makeAccountFormCompletion(
        result: AccountOperationResult,
        createdAccount: (any CryptoAccountModel)?,
        wallet: UserWalletModel?
    ) -> () -> Void {
        let openManageTokens: () -> Void = { [weak self] in
            guard let self, let createdAccount, let wallet else { return }

            host?.openManageTokens(for: createdAccount, in: wallet)
        }

        guard let names = result.redistributedAccountNames else {
            return openManageTokens
        }

        return { [weak self] in
            self?.alertPresenter.present(alert: AlertBuilder.makeAlertWithDefaultPrimaryButton(
                title: Localization.accountsMigrationAlertTitle,
                message: Localization.accountsMigrationAlertMessage(
                    names.source,
                    names.target
                ),
                buttonText: Localization.commonGotIt,
                buttonAction: openManageTokens
            ))
        }
    }
}
