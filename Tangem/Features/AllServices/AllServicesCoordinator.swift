//
//  AllServicesCoordinator.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemLocalization

final class AllServicesCoordinator: CoordinatorObject {
    let dismissAction: Action<DismissOptions?>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Dependencies

    @Injected(\.alertPresenter) private var alertPresenter: AlertPresenter
    @Injected(\.mailComposePresenter) private var mailPresenter: MailComposePresenter
    @Injected(\.safariManager) private var safariManager: SafariManager

    // MARK: - Root view model

    @Published private(set) var rootViewModel: AllServicesViewModel?

    // MARK: - Child coordinators

    @Published var addWalletCoordinator: AddWalletCoordinator?
    @Published var modalOnboardingCoordinator: OnboardingCoordinator?
    @Published var jointAccountManagementCoordinator: JointAccountManagementCoordinator?
    @Published var referralCoordinator: ReferralCoordinator?

    // MARK: - Child view models

    @Published var accountFormViewModel: AccountFormViewModel?
    @Published var walletSelectorViewModel: UserWalletSelectorViewModel?

    // MARK: - Pending navigation

    private weak var accountCreationWalletSubject: CurrentValueSubject<UserWalletModel, Never>?
    private var accountFormCompletion: (() -> Void)?
    private var walletSelectorCompletion: (@MainActor () -> Void)?

    // MARK: - Helpers

    @Published var modalOnboardingCoordinatorKeeper: Bool = false

    required init(
        dismissAction: @escaping Action<DismissOptions?>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        rootViewModel = AllServicesViewModel(
            itemsProvider: AllServicesItemsProvider(),
            referralEntryProvider: ReferralServiceEntryProvider(),
            coordinator: self
        )
        addWalletCoordinator = makeAddWalletCoordinator()
    }

    func accountFormDidDismiss() {
        let completion = accountFormCompletion
        accountFormCompletion = nil
        completion?()
    }

    @MainActor
    func walletSelectorDidDismiss() {
        let completion = walletSelectorCompletion
        walletSelectorCompletion = nil
        completion?()
    }
}

// MARK: - AllServicesRoutable

extension AllServicesCoordinator: AllServicesRoutable {
    func openAddWallet() {
        addWalletCoordinator?.start(with: .init())
    }

    func openOnboardingModal(with input: OnboardingInput) {
        let dismissAction: Action<OnboardingCoordinator.OutputOptions> = { [weak self] result in
            self?.modalOnboardingCoordinator = nil

            if result.isSuccessful {
                self?.dismiss(with: nil)
            }
        }

        let coordinator = OnboardingCoordinator(dismissAction: dismissAction)
        coordinator.start(with: .input(input))
        modalOnboardingCoordinator = coordinator
    }

    func openMail(with dataCollector: EmailDataCollector, recipient: String) {
        let logsComposer = LogsComposer(infoProvider: dataCollector)
        let mailViewModel = MailViewModel(logsComposer: logsComposer, recipient: recipient, emailType: .failedToScanCard)

        Task { @MainActor in
            mailPresenter.present(viewModel: mailViewModel)
        }
    }

    func openScanCardManual() {
        safariManager.openURL(TangemBlogUrlBuilder().url(post: .scanCard))
    }

    func openShop() {
        safariManager.openURL(TangemShopUrlBuilder().url(utmCampaign: .users))
    }

    func openCryptoAccountForm() {
        let wallets = UserWalletModelsProvider.accountCreationCandidates(for: .crypto)

        guard validateAccountLimit(in: wallets), let wallet = UserWalletModelsProvider.default(from: wallets) else {
            return
        }

        let walletSubject = CurrentValueSubject<UserWalletModel, Never>(wallet)
        let walletSelection: AccountFormWalletSelection = wallets.count > 1 ? .selectable : .hidden

        accountCreationWalletSubject = walletSubject
        accountFormViewModel = AccountFormViewModel(
            flowType: .create(
                creator: CryptoAccountFormViewCreator(userWalletModelSubject: walletSubject, walletSelection: walletSelection)
            ),
            coordinator: self
        )
    }

    func openJointAccountCreation() {
        Analytics.log(event: .jointAccountButtonCreateJointAccount, params: [.source: Analytics.JointAccountCreationSource.mainScreen.rawValue])

        let wallets = UserWalletModelsProvider.accountCreationCandidates(for: .joint)

        guard validateAccountLimit(in: wallets) else {
            Analytics.logJointAccountAccountsLimitReached(flow: .create)
            return
        }

        guard let wallet = UserWalletModelsProvider.default(from: wallets) else { return }

        let coordinator = JointAccountManagementCoordinator(
            dismissAction: { [weak self] in
                self?.jointAccountManagementCoordinator = nil
            },
            popToRootAction: popToRootAction
        )

        coordinator.start(with: .creation(
            JointAccountCreationHelper(userWalletModel: wallet),
            isWalletFixed: false,
            source: .mainScreen
        ))
        jointAccountManagementCoordinator = coordinator
    }

    func openReferral(wallets: [UserWalletModel]) {
        Task { @MainActor [weak self] in
            self?.selectWallet(from: wallets) { [weak self] wallet in
                self?.openReferral(for: wallet)
            }
        }
    }

    func closeAllServices() {
        dismiss(with: nil)
    }
}

// MARK: - AccountFormViewModelRoutable

extension AllServicesCoordinator: AccountFormViewModelRoutable {
    func closeAccountForm(outcome: AccountFormOutcome) {
        guard let walletSubject = accountCreationWalletSubject else { return }

        if case .completed(.crypto(let result, let createdAccount)) = outcome {
            accountFormCompletion = makeAccountFormCompletion(
                result: result,
                createdAccount: createdAccount,
                wallet: walletSubject.value
            )
        }

        accountCreationWalletSubject = nil
        accountFormViewModel = nil
    }
}

// MARK: - Private

private extension AllServicesCoordinator {
    func validateAccountLimit(in wallets: [UserWalletModel]) -> Bool {
        guard wallets.isEmpty else { return true }

        alertPresenter.present(alert: AccountEditErrorAlertBuilder.makeAlert(for: .tooManyAccounts))
        return false
    }

    func makeAccountFormCompletion(
        result: AccountOperationResult,
        createdAccount: (any CryptoAccountModel)?,
        wallet: UserWalletModel
    ) -> () -> Void {
        let openManageTokens: () -> Void = { [weak self] in
            guard let createdAccount else { return }

            self?.dismiss(with: .openManageTokens(account: createdAccount, userWalletModel: wallet))
        }

        guard let names = result.redistributedAccountNames else {
            return openManageTokens
        }

        return { [weak self] in
            self?.alertPresenter.present(alert: AlertBuilder.makeAlertWithDefaultPrimaryButton(
                title: Localization.accountsMigrationAlertTitle,
                message: Localization.accountsMigrationAlertMessage(names.source, names.target),
                buttonText: Localization.commonGotIt,
                buttonAction: openManageTokens
            ))
        }
    }

    func openReferral(for wallet: UserWalletModel) {
        let coordinator = ReferralCoordinator(
            dismissAction: { [weak self] _ in
                self?.referralCoordinator = nil
            },
            popToRootAction: popToRootAction
        )

        coordinator.start(with: .init(input: ReferralInputModel(
            userWalletId: wallet.userWalletId.value,
            supportedBlockchains: wallet.config.supportedBlockchains,
            accountModelsManager: wallet.accountModelsManager,
            tokenIconInfoBuilder: TokenIconInfoBuilder(),
            userWalletModel: wallet
        )))

        referralCoordinator = coordinator
    }

    @MainActor
    func selectWallet(from wallets: [UserWalletModel], then next: @escaping @MainActor (UserWalletModel) -> Void) {
        guard let wallet = wallets.first else { return }

        guard wallets.count > 1 else {
            next(wallet)
            return
        }

        walletSelectorViewModel = UserWalletSelectorViewModel(
            userWalletsProvider: FixedUserWalletsProvider(userWalletModels: wallets)
        ) { [weak self] userWalletId in
            guard let wallet = wallets.first(where: { $0.userWalletId == userWalletId }) else { return }

            self?.walletSelectorCompletion = { next(wallet) }
            self?.walletSelectorViewModel = nil
        }
    }
}

// MARK: - FixedUserWalletsProvider

private struct FixedUserWalletsProvider: UserWalletSelectorUserWalletsProvider {
    let userWalletModels: [any UserWalletModel]
}

// MARK: - Add wallet

private extension AllServicesCoordinator {
    func makeAddWalletCoordinator() -> AddWalletCoordinator {
        let dismissAction: Action<AddWalletCoordinator.OutputOptions> = { [weak self] options in
            self?.handleAddWalletDismiss(with: options)
        }

        return AddWalletCoordinator(dismissAction: dismissAction, popToRootAction: popToRootAction)
    }

    func handleAddWalletDismiss(with options: AddWalletCoordinator.OutputOptions) {
        Task { @MainActor [weak self] in
            switch options {
            case .main:
                self?.dismiss(with: nil)
            case .hardwareWallet:
                self?.rootViewModel?.scanCard()
            case .dismiss:
                break
            }
        }
    }
}

// MARK: - Options

extension AllServicesCoordinator {
    struct Options {}

    enum DismissOptions {
        case openManageTokens(account: any CryptoAccountModel, userWalletModel: UserWalletModel)
    }
}
