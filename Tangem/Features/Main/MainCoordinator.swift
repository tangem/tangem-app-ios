//
//  MainCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import CombineExt
import BlockchainSdk
import TangemVisa
import TangemNFT
import TangemFoundation
import TangemUI
import TangemMobileWalletSdk
import TangemPay
import TangemLocalization

final class MainCoordinator: CoordinatorObject, FeeCurrencyNavigating {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Dependencies

    @Injected(\.mailComposePresenter) private var mailPresenter: MailComposePresenter
    @Injected(\.safariManager) private var safariManager: SafariManager
    @Injected(\.pushNotificationsInteractor) private var pushNotificationsInteractor: PushNotificationsInteractor
    @Injected(\.mainBottomSheetUIManager) private var mainBottomSheetUIManager: MainBottomSheetUIManager
    @Injected(\.tangemStoriesPresenter) private var tangemStoriesPresenter: any TangemStoriesPresenter
    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: FloatingSheetPresenter
    @Injected(\.mobileFinishActivationManager) private var mobileFinishActivationManager: MobileFinishActivationManager

    private let coordinatorFactory: MainCoordinatorChildFactory
    private let hardwareUpgradeStoriesFlow = HardwareUpgradeStoriesFlow()

    // MARK: - Root view model

    @Published private(set) var mainViewModel: MainViewModel?

    // MARK: - Child coordinators (Push presentation)

    @Published var detailsCoordinator: DetailsCoordinator?
    @Published var tokenDetailsCoordinator: TokenDetailsCoordinator?
    @Published var marketsTokenDetailsCoordinator: MarketsTokenDetailsCoordinator?
    @Published var stakingDetailsCoordinator: StakingDetailsCoordinator?
    @Published var nftCollectionsCoordinator: NFTCollectionsCoordinator?
    @Published var yieldModulePromoCoordinator: YieldModulePromoCoordinator?
    @Published var yieldModuleActiveCoordinator: YieldModuleActiveCoordinator?
    @Published var hardwareBackupTypesCoordinator: HardwareBackupTypesCoordinator?
    @Published var manageTokensCoordinator: ManageTokensCoordinator?
    @Published var polymarketCoordinator: PolymarketCoordinator?
    @Published var collectiblesCoordinator: CollectiblesCoordinator?
    @Published var jointAccountManagementCoordinator: JointAccountManagementCoordinator?

    // MARK: - Child coordinators (Other)

    @Published var modalOnboardingCoordinator: OnboardingCoordinator?
    @Published var sendCoordinator: SendCoordinator? = nil
    @Published var actionButtonsBuyCoordinator: ActionButtonsBuyCoordinator? = nil
    @Published var actionButtonsSellCoordinator: ActionButtonsSellCoordinator? = nil
    @Published var tangemPayMainCoordinator: TangemPayMainCoordinator?
    @Published var tangemPaySelectPlanCoordinator: TangemPaySelectPlanCoordinator?
    @Published var tangemPayOnboardingCoordinator: TangemPayOnboardingCoordinator?
    @Published var tangemPayCampaignCoordinator: TangemPayCampaignCoordinator?
    @Published var mobileBackupTypesCoordinator: MobileBackupTypesCoordinator?
    @Published var mainQRScanFlowCoordinator: MainQRScanFlowCoordinator?

    private(set) var shtorka: MainShtorkaPresenter?

    // MARK: - Child view models

    @Published var visaTransactionDetailsViewModel: VisaTransactionDetailsViewModel?

    // MARK: - Helpers

    @Published var modalOnboardingCoordinatorKeeper = false
    @Published var isAppStoreReviewRequested = false
    @Published var isMarketsTooltipVisible = false

    private lazy var marketsTooltipScheduler = MarketsTooltipScheduler()

    // MARK: - Deeplink

    private let mainScreenDeeplinkResponder = MainScreenDeeplinkResponder()
    private var pendingIncomingAction: IncomingAction?

    private var safariHandle: SafariHandle?
    private var tangemPayCampaignPendingKeySubscription: AnyCancellable?
    private var tangemPayMainDismissSubscription: AnyCancellable?

    required init(
        coordinatorFactory: MainCoordinatorChildFactory,
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.coordinatorFactory = coordinatorFactory
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction

        mainScreenDeeplinkResponder.coordinator = self
    }

    deinit {
        hardwareUpgradeStoriesFlow.cancel()
    }

    func start(with options: Options) {
        let factory = PushNotificationsHelpersFactory()
        let pushNotificationsAvailabilityProvider = factory.makeAvailabilityProviderForAfterLogin(using: pushNotificationsInteractor)
        let viewModel = MainViewModel(
            selectedUserWalletId: options.userWalletModel.userWalletId,
            coordinator: self,
            mainUserWalletPageBuilderFactory: CommonMainUserWalletPageBuilderFactory(coordinator: self),
            pushNotificationsAvailabilityProvider: pushNotificationsAvailabilityProvider
        )

        mainViewModel = viewModel

        let userWalletModel = options.userWalletModel
        mobileFinishActivationManager.observeUserWallet(
            id: userWalletModel.userWalletId,
            config: userWalletModel.config,
            onActivation: weakify(self, forFunction: MainCoordinator.openMobileFinishActivation)
        )

        shtorka = MainShtorkaPresenter(host: self, popToRootAction: popToRootAction)
    }

    // MARK: - Tooltip Interaction

    func showMarketsTooltip() {
        marketsTooltipScheduler.scheduleShow(delay: Constants.tooltipAnimationDelay) { [weak self] in
            withAnimation(.easeInOut(duration: Constants.tooltipAnimationDuration)) {
                self?.isMarketsTooltipVisible = true
            }
        }
    }

    func dismissMarketsTooltip() {
        marketsTooltipScheduler.dismiss { [weak self] in
            withAnimation(.easeInOut(duration: Constants.tooltipAnimationDuration)) {
                self?.isMarketsTooltipVisible = false
            }
        }
    }

    func hideMarketsTooltipTemporarily() {
        marketsTooltipScheduler.hideTemporarily(
            isVisible: { [weak self] in
                self?.isMarketsTooltipVisible ?? false
            },
            onHide: { [weak self] in
                withAnimation(.easeInOut(duration: Constants.tooltipTemporaryHideDuration)) {
                    self?.isMarketsTooltipVisible = false
                }
            }
        )
    }
}

// MARK: - Options

extension MainCoordinator {
    struct Options {
        let userWalletModel: UserWalletModel
    }
}

// MARK: - MainRoutable protocol conformance

extension MainCoordinator: MainRoutable {
    func mainScreenDidAppear() {
        let incomingAction = pendingIncomingAction
        pendingIncomingAction = nil
        mainScreenDeeplinkResponder.mainScreenDidAppear(delivering: incomingAction)
        observePendingTangemPayCampaign()
    }

    /// The link that arrived before there was a session: shown once the main screen is up, or right away if it
    /// already is.
    func showWhenAppeared(_ action: IncomingAction) {
        guard mainViewModel?.isRootVisible == true else {
            pendingIncomingAction = action
            return
        }

        mainScreenDeeplinkResponder.mainScreenDidAppear(delivering: action)
    }

    func openDetails() {
        mainBottomSheetUIManager.hide()

        let dismissAction: Action<Void> = { [weak self] _ in
            self?.detailsCoordinator = nil
        }

        let coordinator = DetailsCoordinator(dismissAction: dismissAction, popToRootAction: popToRootAction)
        coordinator.start(with: .default)
        detailsCoordinator = coordinator
    }

    func openQRScan() {
        let dismissAction: Action<MainQRScanFlowCoordinator.DismissOptions?> = { [weak self] options in
            self?.mainQRScanFlowCoordinator = nil

            if case .openFeeCurrency(let option) = options {
                self?.proceedFeeCurrencyNavigatingDismissOption(option: option)
            }
        }

        let coordinator = MainQRScanFlowCoordinator(
            dismissAction: dismissAction,
            popToRootAction: popToRootAction
        )
        coordinator.start(with: .init())
        mainQRScanFlowCoordinator = coordinator
    }

    func openMail(with dataCollector: EmailDataCollector, emailType: EmailType, recipient: String) {
        let logsComposer = LogsComposer(infoProvider: dataCollector)
        let mailViewModel = MailViewModel(logsComposer: logsComposer, recipient: recipient, emailType: emailType)

        Task { @MainActor in
            mailPresenter.present(viewModel: mailViewModel)
        }
    }

    func openOnboardingModal(with options: OnboardingCoordinator.Options) {
        let dismissAction: Action<OnboardingCoordinator.OutputOptions> = { [weak self] _ in
            self?.modalOnboardingCoordinator = nil
        }

        let coordinator = OnboardingCoordinator(dismissAction: dismissAction)
        coordinator.start(with: options)
        modalOnboardingCoordinator = coordinator
    }

    func close(newScan: Bool) {
        popToRoot(with: .init(newScan: newScan))
    }

    func openScanCardManual() {
        safariManager.openURL(TangemBlogUrlBuilder().url(post: .scanCard))
    }

    func openPushNotificationsAuthorization() {
        let factory = PushNotificationsHelpersFactory()
        let permissionManager = factory.makePermissionManagerForAfterLogin(using: pushNotificationsInteractor)

        Task { @MainActor in
            let viewModel = PushNotificationsMainViewModel(permissionManager: permissionManager)
            viewModel.start()
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }
}

// MARK: - MultiWalletMainContentRoutable protocol conformance

extension MainCoordinator: MultiWalletMainContentRoutable {
    func openYieldModulePromoView(apy: Decimal, factory: YieldModuleFlowFactory) {
        let dismissAction: Action<YieldModulePromoCoordinator.DismissOptions?> = { [weak self] option in
            self?.yieldModulePromoCoordinator = nil
            self?.proceedFeeCurrencyNavigatingDismissOption(option: option)
        }

        mainBottomSheetUIManager.hide()
        let coordinator = factory.makeYieldPromoCoordinator(apy: apy, isApyBoostPromo: false, dismissAction: dismissAction)
        yieldModulePromoCoordinator = coordinator
    }

    func openGetTangemPay(availableSelection: TangemPayWalletSelectionType) {
        openGetTangemPay(source: .other, availableSelection: availableSelection)
    }

    func openGetTangemPay(source: TangemPayOnboardingSource, availableSelection: TangemPayWalletSelectionType) {
        let dismissAction: Action<TangemPayOnboardingCoordinator.DismissOptions?> = { [weak self] _ in
            self?.tangemPayOnboardingCoordinator = nil
        }

        let coordinator = TangemPayOnboardingCoordinator(dismissAction: dismissAction)
        coordinator.start(with: .init(source: source, availableSelection: availableSelection))
        tangemPayOnboardingCoordinator = coordinator
    }

    func openYieldModuleActiveInfo(factory: YieldModuleFlowFactory) {
        let dismissAction: Action<YieldModuleActiveCoordinator.DismissOptions?> = { [weak self] option in
            self?.yieldModuleActiveCoordinator = nil
            self?.proceedFeeCurrencyNavigatingDismissOption(option: option)
        }

        let coordinator = factory.makeYieldActiveCoordinator(dismissAction: dismissAction)
        yieldModuleActiveCoordinator = coordinator
    }

    func openCloreMigration(walletModel: any WalletModel) {
        Task { @MainActor in
            floatingSheetPresenter.enqueue(
                sheet: CommonCloreMigrationModuleFlowFactory(walletModel: walletModel, coordinator: self).makeCloreMigrationViewModel()
            )
        }
    }

    func openTokenDetails(for walletModel: any WalletModel, userWalletModel: UserWalletModel) {
        openTokenDetails(for: walletModel, userWalletModel: userWalletModel, pendingTransactionDetails: nil)
    }

    func openTokenDetails(
        for walletModel: any WalletModel,
        userWalletModel: UserWalletModel,
        pendingTransactionDetails: PendingTransactionDetails?
    ) {
        mainBottomSheetUIManager.hide()

        let coordinator = coordinatorFactory.makeTokenDetailsCoordinator(dismissAction: { [weak self] in
            self?.tokenDetailsCoordinator = nil
        })

        guard let account = walletModel.account else {
            let message = "Inconsistent state: WalletModel '\(walletModel.name)' has no account in accounts-enabled build"
            AppLogger.error(error: message)
            assertionFailure(message)
            return
        }

        coordinator.start(
            with: .init(
                userWalletInfo: userWalletModel.userWalletInfo,
                keysDerivingInteractor: userWalletModel.keysDerivingInteractor,
                walletModelsManager: account.walletModelsManager,
                userTokensManager: account.userTokensManager,
                addressBookManager: userWalletModel.addressBookManager,
                walletModel: walletModel,
                pendingTransactionDetails: pendingTransactionDetails
            )
        )

        tokenDetailsCoordinator = coordinator
    }

    func openAddAndManageTokens(factory: TokensManagementFlowFactory) {
        Task { @MainActor in
            let viewModel = factory.makeFlowViewModel(coordinator: self)
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }

    func openManageTokens(for account: any CryptoAccountModel, in userWalletModel: UserWalletModel) {
        mainBottomSheetUIManager.hide()

        let manageTokensCoordinator = ManageTokensCoordinator(
            dismissAction: { [weak self] in
                self?.manageTokensCoordinator = nil
            },
            popToRootAction: popToRootAction
        )

        let context = CommonManageTokensContext(
            accountModelsManager: userWalletModel.accountModelsManager,
            currentAccount: account
        )

        manageTokensCoordinator.start(
            with: ManageTokensCoordinator.Options(
                context: context,
                userWalletConfig: userWalletModel.config,
                analyticsSourceRawValue: Analytics.ParameterValue.main.rawValue
            )
        )

        self.manageTokensCoordinator = manageTokensCoordinator
    }

    func openMobileFinishActivation(userWalletModel: UserWalletModel) {
        Task { @MainActor in
            floatingSheetPresenter.enqueue(
                sheet: MobileFinishActivationNeededViewModel(userWalletModel: userWalletModel, coordinator: self)
            )
        }
    }

    func openHardwareBackupTypes(userWalletModel: UserWalletModel) {
        mainBottomSheetUIManager.hide()

        Task { @MainActor [hardwareUpgradeStoriesFlow] in
            hardwareUpgradeStoriesFlow.start(source: .main) { [weak self] in
                self?.presentHardwareBackupTypes(userWalletModel: userWalletModel)
            }
        }
    }

    private func presentHardwareBackupTypes(userWalletModel: UserWalletModel) {
        let dismissAction: Action<HardwareBackupTypesCoordinator.OutputOptions> = { [weak self] options in
            switch options {
            case .main:
                self?.hardwareBackupTypesCoordinator = nil
            }
        }

        let inputOptions = HardwareBackupTypesCoordinator.InputOptions(userWalletModel: userWalletModel)
        let coordinator = HardwareBackupTypesCoordinator(dismissAction: dismissAction)
        coordinator.start(with: inputOptions)
        hardwareBackupTypesCoordinator = coordinator
    }

    func openTangemPayKYCInProgressPopup(tangemPayKYCInteractor: TangemPayKYCInteractor) {
        Task { @MainActor in
            let viewModel = TangemPayKYCStatusPopupViewModel(
                tangemPayKYCInteractor: tangemPayKYCInteractor,
                coordinator: self
            )

            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }

    func openTangemPayKYCDeclinedPopup(tangemPayKYCInteractor: TangemPayKYCInteractor) {
        Task { @MainActor in
            let viewModel = TangemPayKYCDeclinedPopupViewModel(
                tangemPayKYCInteractor: tangemPayKYCInteractor,
                coordinator: self
            )
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }

    func openTangemPayResidency(interactor: any TangemPayResidencyInteractor) {
        let dismissAction: Action<TangemPayOnboardingCoordinator.DismissOptions?> = { [weak self] _ in
            self?.tangemPayOnboardingCoordinator = nil
        }

        let coordinator = TangemPayOnboardingCoordinator(dismissAction: dismissAction)
        coordinator.start(with: .init(residencyInteractor: interactor))
        tangemPayOnboardingCoordinator = coordinator
    }

    func openTangemPayRegionUnavailablePopup(region: TangemPayUnavailableRegion, interactor: any TangemPayResidencyInteractor) {
        Task { @MainActor in
            let viewModel = TangemPayRegionUnavailablePopupViewModel(
                region: region,
                interactor: interactor,
                coordinator: self
            )
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }

    func openTangemPayFailedToIssueCardPopup(userWalletModel: UserWalletModel) {
        Task { @MainActor in
            let viewModel = TangemPayFailedToIssueCardSheetViewModel(
                userWalletModel: userWalletModel,
                coordinator: self
            )
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }

    func openTangemPayMainView(
        userWalletInfo: UserWalletInfo,
        tangemPayAccount: TangemPayAccount,
        userWalletModel: any UserWalletModel,
        openingAction: TangemPayOpeningAction?
    ) {
        mainBottomSheetUIManager.hide()

        let dismissAction: Action<FeeCurrencyNavigatingDismissOption?> = { [weak self] dismissOptions in
            self?.tangemPayMainCoordinator = nil
            self?.proceedFeeCurrencyNavigatingDismissOption(option: dismissOptions)
        }

        let coordinator = TangemPayMainCoordinator(
            dismissAction: dismissAction,
            popToRootAction: popToRootAction
        )

        coordinator.start(
            with: .init(
                userWalletInfo: userWalletInfo,
                tangemPayAccount: tangemPayAccount,
                userWalletModel: userWalletModel,
                openingAction: openingAction
            )
        )
        tangemPayMainCoordinator = coordinator

        tangemPayMainDismissSubscription = $tangemPayMainCoordinator
            .filter { $0 == nil }
            .first()
            .sink { _ in
                runTask {
                    await tangemPayAccount.loadCustomerInfo()
                }
            }
    }

    func openTangemPaySelectPlan(
        tariffPlanSelector: any TangemPayTariffPlanSelector,
        userWalletModel: any UserWalletModel
    ) {
        mainBottomSheetUIManager.hide()

        let coordinator = TangemPaySelectPlanCoordinator(
            dismissAction: { [weak self] reason in
                self?.tangemPaySelectPlanCoordinator = nil

                switch reason {
                case .planUpgraded:
                    self?.openTangemPayMainViewAfterPlanActivation(userWalletModel: userWalletModel)
                case .planDowngraded, .closed:
                    break
                }
            },
            popToRootAction: popToRootAction
        )
        coordinator.start(with: .init(tariffPlanSelector: tariffPlanSelector, mode: .onboarding))
        tangemPaySelectPlanCoordinator = coordinator
    }

    private func openTangemPayMainViewAfterPlanActivation(userWalletModel: any UserWalletModel) {
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.tangemPayPlanActivationNavigationDelay) { [weak self] in
            guard let tangemPayAccount = AccountModelsAggregator(.tangemPay).model(from: userWalletModel.accountModelsManager)?.state?.tangemPayAccount else {
                return
            }

            self?.openTangemPayMainView(
                userWalletInfo: userWalletModel.userWalletInfo,
                tangemPayAccount: tangemPayAccount,
                userWalletModel: userWalletModel,
                openingAction: nil
            )
        }
    }

    /// A deferred AppsFlyer link resolves after launch, and on a relaunch with a wallet already present the
    /// app never builds `WelcomeProcessor` — so the stored key has no other route onto the screen here.
    private func observePendingTangemPayCampaign() {
        let keyChanges: AnyPublisher<Void, Never> = TangemPayCampaignService()
            .pendingCampaignKeyPublisher
            .mapToVoid()
            .receiveOnMain()
            .eraseToAnyPublisher()

        // Slots change in `willSet`, with UIKit still animating the dismissal — presenting into that
        // makes SwiftUI drop the cover, so this branch waits the animation out.
        let slotChanges: AnyPublisher<Void, Never> = presentationSlotChanges
            .delay(for: .seconds(Constants.tangemPayCampaignPresentationDelay), scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()

        // The stored key replays on subscribe, and a slot change re-checks a key some modal was covering.
        // Whether the main screen is the top is read at delivery, as is the key — by then some other route
        // may have spent it, and the main screen may have a child of its own over it.
        tangemPayCampaignPendingKeySubscription = Publishers
            .Merge(keyChanges, slotChanges)
            .sink { [weak self] _ in
                guard let self,
                      isRootVisible,
                      !isPresentingOverMain,
                      let campaignKey = TangemPayCampaignService().pendingCampaignKey else {
                    return
                }

                openTangemPayCampaign(campaignKey: campaignKey)
            }
    }

    func openTangemPayCampaign(campaignKey: String) {
        guard !RTCUtil.isRootedDevice else {
            TangemPayCampaignService().clearPending()
            return
        }

        // Already on screen, so the link has been honoured — drop it rather than leaving it to fire again.
        guard tangemPayCampaignCoordinator == nil else {
            TangemPayCampaignService().clearPending()
            return
        }

        // The campaign replaces the Payment account screen rather than stacking on top of it, so pop that
        // push first and let the navigation animation finish before the cover goes up.
        guard tangemPayMainCoordinator == nil else {
            tangemPayMainCoordinator = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + Constants.tangemPayCampaignPresentationDelay) { [weak self] in
                self?.presentTangemPayCampaign(campaignKey: campaignKey)
            }
            return
        }

        presentTangemPayCampaign(campaignKey: campaignKey)
    }

    /// The campaign cover shares a host with every other modal in `MainCoordinatorView`, and SwiftUI drops
    /// the second presentation rather than queueing it — leaving a coordinator no view will ever clear.
    private var isPresentingOverMain: Bool {
        tangemPayOnboardingCoordinator != nil
            || mainQRScanFlowCoordinator != nil
            || jointAccountManagementCoordinator != nil
            || sendCoordinator != nil
            || modalOnboardingCoordinator != nil
            || visaTransactionDetailsViewModel != nil
            || actionButtonsBuyCoordinator != nil
            || actionButtonsSellCoordinator != nil
            || yieldModuleActiveCoordinator != nil
    }

    /// Changes to the slots `isPresentingOverMain` reads, so a campaign that a modal was covering gets
    /// another chance once it goes away. Only changes matter, hence `dropFirst`.
    private var presentationSlotChanges: AnyPublisher<Void, Never> {
        let slots: [AnyPublisher<Void, Never>] = [
            $tangemPayOnboardingCoordinator.dropFirst().mapToVoid().eraseToAnyPublisher(),
            $mainQRScanFlowCoordinator.dropFirst().mapToVoid().eraseToAnyPublisher(),
            $jointAccountManagementCoordinator.dropFirst().mapToVoid().eraseToAnyPublisher(),
            $sendCoordinator.dropFirst().mapToVoid().eraseToAnyPublisher(),
            $modalOnboardingCoordinator.dropFirst().mapToVoid().eraseToAnyPublisher(),
            $visaTransactionDetailsViewModel.dropFirst().mapToVoid().eraseToAnyPublisher(),
            $actionButtonsBuyCoordinator.dropFirst().mapToVoid().eraseToAnyPublisher(),
            $actionButtonsSellCoordinator.dropFirst().mapToVoid().eraseToAnyPublisher(),
            $yieldModuleActiveCoordinator.dropFirst().mapToVoid().eraseToAnyPublisher(),
        ]

        return Publishers.MergeMany(slots).eraseToAnyPublisher()
    }

    private func presentTangemPayCampaign(campaignKey: String) {
        guard tangemPayCampaignCoordinator == nil else { return }

        // Leaving the key unconsumed lets the pending-key subscription retry once the blocking screen goes.
        guard !isPresentingOverMain else { return }

        TangemPayCampaignService().clearPending()

        let dismissAction: Action<TangemPayCampaignCoordinator.OutputOptions> = { [weak self] options in
            self?.tangemPayCampaignCoordinator = nil

            switch options {
            case .close:
                break
            case .finished(let userWalletModel):
                self?.openTangemPayMainAfterCampaign(userWalletModel: userWalletModel, openingAction: nil)
            case .finishedWithPlanSelection(let userWalletModel):
                self?.openTangemPayMainAfterCampaign(userWalletModel: userWalletModel, openingAction: .selectPlan)
            }
        }

        let coordinator = TangemPayCampaignCoordinator(
            dismissAction: dismissAction,
            popToRootAction: popToRootAction
        )
        coordinator.start(with: .init(campaignKey: campaignKey))
        tangemPayCampaignCoordinator = coordinator
    }

    private func openTangemPayMainAfterCampaign(
        userWalletModel: any UserWalletModel,
        openingAction: TangemPayOpeningAction?
    ) {
        guard let tangemPayAccount = AccountModelsAggregator(.tangemPay)
            .model(from: userWalletModel.accountModelsManager)?
            .state?
            .tangemPayAccount
        else {
            return
        }

        openTangemPayMainView(
            userWalletInfo: userWalletModel.userWalletInfo,
            tangemPayAccount: tangemPayAccount,
            userWalletModel: userWalletModel,
            openingAction: openingAction
        )
    }

    func openPolymarket(userWalletModel: UserWalletModel) {
        mainBottomSheetUIManager.hide()

        let coordinator = PolymarketCoordinator(
            dismissAction: { [weak self] in
                self?.polymarketCoordinator = nil
                self?.mainBottomSheetUIManager.show()
            },
            popToRootAction: popToRootAction
        )
        coordinator.start(with: .init(userWalletModel: userWalletModel))
        polymarketCoordinator = coordinator
    }

    func openCollectibles(with options: CollectiblesCoordinator.Options) {
        mainBottomSheetUIManager.hide()

        let coordinator = CollectiblesCoordinator(
            dismissAction: { [weak self] in
                self?.collectiblesCoordinator = nil
                self?.mainBottomSheetUIManager.show()
            },
            popToRootAction: popToRootAction
        )
        coordinator.start(with: options)
        collectiblesCoordinator = coordinator
    }

    func openJointAccountMembers(jointAccount: any JointAccountModel, userWalletConfig: UserWalletConfig) {
        let coordinator = JointAccountManagementCoordinator(
            dismissAction: { [weak self] in
                self?.jointAccountManagementCoordinator = nil
            },
            popToRootAction: popToRootAction
        )
        coordinator.start(with: .members(jointAccount: jointAccount, userWalletConfig: userWalletConfig))
        jointAccountManagementCoordinator = coordinator
    }

    func openJointAccountOperationDetails(pendingOperation: JointAccountPendingOperation, userWalletInfo: UserWalletInfo) {
        let viewModel = JointAccountOperationDetailsViewModelBuilder().build(
            pendingOperation: pendingOperation,
            userWalletInfo: userWalletInfo,
            coordinator: self
        )

        Task { @MainActor in
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }
}

// MARK: - JointAccountOperationDetailsRoutable

extension MainCoordinator: JointAccountOperationDetailsRoutable {
    func closeOperationDetails() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }
}

// MARK: - CloreMigrationRoutable

extension MainCoordinator: CloreMigrationRoutable {
    func openURLInSystemBrowser(url: URL) {
        UIApplication.shared.open(url)
    }
}

// MARK: - SingleTokenBaseRoutable

extension MainCoordinator: SingleTokenBaseRoutable {
    func openReceiveScreen(walletModel: any WalletModel) {
        let receiveFlowFactory = AvailabilityReceiveFlowFactory(
            flow: .crypto,
            tokenItem: walletModel.tokenItem,
            addressTypesProvider: walletModel
        )

        let viewModel = receiveFlowFactory.makeAvailabilityReceiveFlow()

        Task { @MainActor in
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }

    func openSellCrypto(at url: URL, action: @escaping (String) -> Void) {
        Analytics.log(.withdrawScreenOpened)

        safariHandle = safariManager.openURL(url) { [weak self] closeURL in
            self?.safariHandle = nil
            action(closeURL.absoluteString)
        }
    }

    func openSend(input: SendInput) {
        guard SendFeatureProvider.shared.isAvailable else {
            return
        }

        let sourceTokenFactory = CommonSendSwapableTokenFactory(
            userWalletInfo: input.userWalletInfo,
            walletModel: input.walletModel,
            operationType: .swapAndSend
        )
        let sourceToken = sourceTokenFactory.makeSwapableToken()

        let coordinator = makeSendCoordinator()
        let options = SendCoordinator.Options(type: .send(sourceToken), source: .main)

        coordinator.start(with: options)
        sendCoordinator = coordinator
    }

    func openSwapAndSend(input: SendInput) {
        guard SendFeatureProvider.shared.isAvailable else {
            return
        }

        let sourceToken = CommonSendSwapableTokenFactory(
            userWalletInfo: input.userWalletInfo,
            walletModel: input.walletModel,
            operationType: .swapAndSend
        ).makeSwapableToken()

        let coordinator = makeSendCoordinator()
        let options = SendCoordinator.Options(
            type: .send(sourceToken),
            source: .main,
            shouldStartFromTokenList: true
        )

        coordinator.start(with: options)
        sendCoordinator = coordinator
    }

    func openSwap(parameters: PredefinedSwapParameters) {
        openSwapFlow(parameters: parameters, source: .main)
    }

    func openSendToSell(input: SendInput, sellParameters: PredefinedSellParameters) {
        guard SendFeatureProvider.shared.isAvailable else {
            return
        }

        let sourceToken = CommonSendTransferableTokenFactory(
            userWalletInfo: input.userWalletInfo,
            walletModel: input.walletModel
        ).makeTransferableToken()

        let coordinator = makeSendCoordinator()
        let options = SendCoordinator.Options(
            type: .sell(sourceToken, parameters: sellParameters),
            source: .main
        )
        coordinator.start(with: options)
        sendCoordinator = coordinator
    }

    func openStaking(options: StakingDetailsCoordinator.Options) {
        mainBottomSheetUIManager.hide()

        let dismissAction: Action<Void> = { [weak self] _ in
            self?.stakingDetailsCoordinator = nil
        }

        let coordinator = StakingDetailsCoordinator(dismissAction: dismissAction, popToRootAction: popToRootAction)
        coordinator.start(with: options)
        stakingDetailsCoordinator = coordinator
    }

    func openInSafari(url: URL) {
        safariManager.openURL(url)
    }

    func openMarketsTokenDetails(tokenModel: MarketsTokenModel) {
        openMarketsTokenDetails(options: .init(info: tokenModel, style: .navigationStack))
    }

    func openMarketsTokenChart(tokenId: String) {
        openMarketsTokenDetails(options: .tokenChartDeeplink(tokenId: tokenId))
    }

    private func openMarketsTokenDetails(options: MarketsTokenDetailsCoordinator.Options) {
        mainBottomSheetUIManager.hide()
        let coordinator = coordinatorFactory.makeMarketsTokenDetailsCoordinator()
        coordinator.start(with: options)
        marketsTokenDetailsCoordinator = coordinator
    }

    func openOnramp(input: SendInput, parameters: PredefinedOnrampParameters) {
        let sourceToken = CommonSendTransferableTokenFactory(
            userWalletInfo: input.userWalletInfo,
            walletModel: input.walletModel
        ).makeTransferableToken()

        let coordinator = makeSendCoordinator()
        let options = SendCoordinator.Options(
            type: .onramp(sourceToken, parameters: parameters),
            source: .main
        )
        coordinator.start(with: options)
        sendCoordinator = coordinator
    }
}

// MARK: - SendFeeCurrencyNavigating

extension MainCoordinator: SendFeeCurrencyNavigating {
    func openFeeCurrency(for walletModel: any WalletModel, userWalletModel: UserWalletModel) {
        // We use our own custom implementation instead of the default because
        // we have to call `mainBottomSheetUIManager.hide()` when performing this navigation action from the main screen
        openTokenDetails(for: walletModel, userWalletModel: userWalletModel)
    }
}

// MARK: - TokensManagementFlowRoutable protocol conformance

extension MainCoordinator: TokensManagementFlowRoutable {
    func closeTokensManagementFlow() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }
}

// MARK: - Visa

extension MainCoordinator: VisaWalletRoutable {
    func openTransactionDetails(tokenItem: TokenItem, for record: VisaTransactionRecord, emailConfig: EmailConfig) {
        visaTransactionDetailsViewModel = .init(tokenItem: tokenItem, transaction: record, emailConfig: emailConfig, router: self)
    }

    func openReceiveScreen(tokenItem: TokenItem, addressInfos: [ReceiveAddressInfo]) {
        let addressTypesProvider = VisaReceiveAssetInfoProvider(addressInfos)

        let receiveFlowFactory = AvailabilityReceiveFlowFactory(
            flow: .crypto,
            tokenItem: tokenItem,
            addressTypesProvider: addressTypesProvider
        )

        let viewModel = receiveFlowFactory.makeAvailabilityReceiveFlow()

        Task { @MainActor in
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }
}

extension MainCoordinator: VisaTransactionDetailsRouter {}

extension MainCoordinator: TangemPayFailedToIssueCardRoutable {
    func closeFailedToIssueCardSheet() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }

    func openMailFromFailedToIssueCardSheet(mailViewModel: MailViewModel) {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
            mailPresenter.present(viewModel: mailViewModel)
        }
    }
}

// MARK: - RateAppRoutable protocol conformance

extension MainCoordinator: RateAppRoutable {
    func openAppStoreReview() {
        isAppStoreReviewRequested = true
    }
}

// MARK: - Action buttons buy routable

extension MainCoordinator: ActionButtonsBuyFlowRoutable {
    func openBuy(userWalletModels: [UserWalletModel], preferredWalletId: UserWalletId?) {
        let coordinator = coordinatorFactory.makeBuyCoordinator(
            dismissAction: { [weak self] payload in
                self?.actionButtonsBuyCoordinator = nil
                guard let payload else { return }
                self?.openTokenDetails(for: payload.walletModel, userWalletModel: payload.userWalletModel)
            }
        )

        let options = ActionButtonsBuyCoordinator.Options(
            userWalletModels: userWalletModels,
            preferredWalletId: preferredWalletId
        )

        coordinator.start(with: options)
        actionButtonsBuyCoordinator = coordinator
    }
}

// MARK: - Action buttons sell routable

extension MainCoordinator: ActionButtonsSellFlowRoutable {
    func openSell(userWalletModel: some UserWalletModel, tokenSelectorViewModel: TokenSelectorViewModel) {
        let coordinator = coordinatorFactory.makeSellCoordinator(
            userWalletModel: userWalletModel,
            dismissAction: { [weak self] model in
                self?.actionButtonsSellCoordinator = nil
                guard let model else { return }

                let input = SendInput(userWalletInfo: userWalletModel.userWalletInfo, walletModel: model.walletModel)
                self?.openSendToSell(input: input, sellParameters: model.sellParameters)
            }
        )

        coordinator.start(with: .init(tokenSelectorViewModel: tokenSelectorViewModel))
        actionButtonsSellCoordinator = coordinator
    }
}

// MARK: - ActionButtonsSwapFlowRoutable

extension MainCoordinator: ActionButtonsSwapFlowRoutable {
    func openSwap(predefinedParameters: PredefinedSwapParameters) {
        openSwapFlow(parameters: predefinedParameters, source: .actionButtons)
    }
}

extension MainCoordinator {
    enum Constants {
        static let tooltipAnimationDuration: Double = 0.3
        static let tooltipTemporaryHideDuration: Double = 0.1
        static let tooltipAnimationDelay: Double = 1.5
        static let tangemPayPlanActivationNavigationDelay: TimeInterval = 0.6
        static let tangemPayCampaignPresentationDelay: TimeInterval = 0.35
        static let tangemPayRegionReselectionPresentationDelay: TimeInterval = 0.5
    }
}

extension MainCoordinator: TangemPayKYCStatusRoutable {
    func closeKYCStatusPopup() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }
}

extension MainCoordinator: TangemPayKYCDeclinedRoutable {
    func closeKYCDeclinedPopup() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }
}

// MARK: - TangemPayRegionUnavailableRoutable

extension MainCoordinator: TangemPayRegionUnavailableRoutable {
    func closeTangemPayRegionUnavailablePopup() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }

    func openTangemPayRegionReselection(interactor: any TangemPayResidencyInteractor) {
        CommonTangemPayResidencyAnalyticsLogger().logSelectAnotherRegionTapped()

        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
            try? await Task.sleep(for: .seconds(Constants.tangemPayRegionReselectionPresentationDelay))
            openTangemPayResidency(interactor: interactor)
        }
    }
}

// MARK: - NFTEntrypointRoutable

extension MainCoordinator: NFTEntrypointRoutable {
    func openCollections(
        nftManager: NFTManager,
        accountForNFTCollectionsProvider: any AccountForNFTCollectionsProviding,
        navigationContext: NFTNavigationContext
    ) {
        mainBottomSheetUIManager.hide()

        let coordinator = NFTCollectionsCoordinator(
            dismissAction: { [weak self] in
                self?.nftCollectionsCoordinator = nil
            },
            popToRootAction: { [weak self] options in
                self?.nftCollectionsCoordinator = nil
                self?.popToRoot(with: options)
            }
        )

        coordinator.start(
            with: .init(
                nftManager: nftManager,
                accountForNFTCollectionsProvider: accountForNFTCollectionsProvider,
                navigationContext: navigationContext,
                nftChainIconProvider: NetworkImageProvider(),
                nftChainNameProvider: NFTChainNameProvider(),
                priceFormatter: NFTPriceFormatter(),
                blockchainSelectionAnalytics: NFTAnalytics.BlockchainSelection(
                    logBlockchainChosen: { blockchain in
                        Analytics.log(event: .nftReceiveBlockchainChosen, params: [.blockchain: blockchain])
                    }
                )
            )
        )

        nftCollectionsCoordinator = coordinator
    }
}

// MARK: - WCTransactionRoutable

extension MainCoordinator: WCTransactionRoutable {
    func show(floatingSheetViewModel: some FloatingSheetContentViewModel) {
        UIApplication.mainWindow?.endEditing(true)
        floatingSheetPresenter.enqueue(sheet: floatingSheetViewModel)
    }

    func show(toast: Toast<WarningToast>) {
        toast.present(layout: .top(padding: 20), type: .temporary())
    }
}

// MARK: - MobileFinishActivationNeededRoutable

extension MainCoordinator: MobileFinishActivationNeededRoutable {
    func dismissMobileFinishActivationNeeded() {
        floatingSheetPresenter.removeActiveSheet()
    }

    func openMobileBackup(userWalletModel: UserWalletModel) {
        mainBottomSheetUIManager.hide()

        let dismissAction: Action<MobileBackupTypesCoordinator.OutputOptions> = { [weak self] options in
            switch options {
            case .main:
                self?.mobileBackupTypesCoordinator = nil
            }
        }

        let inputOptions = MobileBackupTypesCoordinator.InputOptions(userWalletModel: userWalletModel, mode: .activate)
        let coordinator = MobileBackupTypesCoordinator(dismissAction: dismissAction)
        coordinator.start(with: inputOptions)
        mobileBackupTypesCoordinator = coordinator
    }

    func openMobileBackupOnboarding(userWalletModel: UserWalletModel, context: MobileWalletContext) {
        let backupInput = MobileOnboardingInput(flow: .walletActivate(
            userWalletModel: userWalletModel,
            source: .main(action: .backup),
            context: context
        ))
        openOnboardingModal(with: .mobileInput(backupInput))
    }
}

// MARK: - Swap Flow Helper

private extension MainCoordinator {
    func openSwapFlow(
        parameters: PredefinedSwapParameters,
        source: SendCoordinator.Source
    ) {
        let coordinator = makeSendCoordinator()
        let options = SendCoordinator.Options(type: .swap(parameters), source: source)

        Task { @MainActor [tangemStoriesPresenter] in
            tangemStoriesPresenter.present(
                story: .swap(.initialWithoutImages),
                analyticsSource: .main,
                presentCompletion: { [weak self] in
                    coordinator.start(with: options)
                    self?.sendCoordinator = coordinator
                }
            )
        }
    }
}

// MARK: - FeedHostRoutable

extension MainCoordinator: FeedHostRoutable {
    func openTangemPay(entry: FeedTangemPayEntry) {
        switch entry {
        case .offer(let availableSelection):
            openGetTangemPay(availableSelection: availableSelection)
        case .kycRequired(let tangemPayKYCInteractor):
            openTangemPayKYCInProgressPopup(tangemPayKYCInteractor: tangemPayKYCInteractor)
        case .residencyRequired(let interactor):
            openTangemPayResidency(interactor: interactor)
        case .regionUnavailable(let region, let interactor):
            openTangemPayRegionUnavailablePopup(region: region, interactor: interactor)
        case .kycDeclined(let tangemPayKYCInteractor):
            openTangemPayKYCDeclinedPopup(tangemPayKYCInteractor: tangemPayKYCInteractor)
        case .selectPlan(let tariffPlanSelector, let userWalletModel):
            openTangemPaySelectPlan(tariffPlanSelector: tariffPlanSelector, userWalletModel: userWalletModel)
        }
    }
}
