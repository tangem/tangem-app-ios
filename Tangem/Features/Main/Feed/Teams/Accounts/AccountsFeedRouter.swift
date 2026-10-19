//
//  AccountsFeedRouter.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
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
    private weak var accountCreationWalletSubject: CurrentValueSubject<any UserWalletModel, Never>?
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
                  !widgetSheetPresenter.isPresenting, candidates.contains(where: \.availability.isAvailable) else { return }

            guard candidates.contains(where: \.availability.joint) else {
                openCryptoAccountForm()
                return
            }

            let viewModel = AddAccountTypeSelectorViewModel(
                // The feed records the entry tap before presenting the selector.
                userWalletConfig: nil,
                coordinator: self
            )
            widgetSheetPresenter.presentAccountTypeSelector(viewModel)
        }
    }
}

// MARK: - AddAccountTypeSelectorRoutable

extension AccountsFeedRouter: AddAccountTypeSelectorRoutable {
    func openCryptoAccountForm() {
        Task { @MainActor [self] in
            let wallets = UserWalletModelsProvider.accountCreationCandidates(for: .crypto)

            guard let navigation, navigation.presented == nil, validateAccountLimit(in: wallets),
                  let wallet = UserWalletModelsProvider.default(from: wallets) else { return }

            widgetSheetPresenter.dismissSelector { [weak self] in
                guard let self else { return }
                guard let navigation = self.navigation, navigation.presented == nil else { return }

                let walletSubject = CurrentValueSubject<any UserWalletModel, Never>(wallet)
                let walletSelection: AccountFormWalletSelection = wallets.count > 1 ? .selectable : .hidden

                let viewModel = AccountFormViewModel(
                    flowType: .create(
                        creator: CryptoAccountFormViewCreator(userWalletModelSubject: walletSubject, walletSelection: walletSelection)
                    ),
                    coordinator: self
                )
                accountCreationWalletSubject = walletSubject
                navigation.present(.accountForm(viewModel), onDismiss: { [weak self] in
                    self?.accountFormDidDismiss()
                })
            }
        }
    }

    func openJointAccountManagement() {
        Task { @MainActor [self] in
            let wallets = UserWalletModelsProvider.accountCreationCandidates(for: .joint)

            guard let navigation, navigation.presented == nil, validateAccountLimit(in: wallets),
                  let wallet = UserWalletModelsProvider.default(from: wallets) else { return }

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
                coordinator.start(with: .creation(JointAccountCreationHelper(userWalletModel: wallet), isWalletFixed: false))
                navigation.present(.jointAccount(coordinator))
            }
        }
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
                wallet: accountCreationWalletSubject?.value
            )
        }
        accountCreationWalletSubject = nil
        navigation.dismissPresented()
    }
}

// MARK: - Widget sheets

@MainActor
private extension AccountsFeedRouter {
    func validateAccountLimit(in wallets: [any UserWalletModel]) -> Bool {
        guard !wallets.isEmpty else {
            alertPresenter.present(alert: AccountEditErrorAlertBuilder.makeAlert(for: .tooManyAccounts))
            return false
        }

        return true
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
