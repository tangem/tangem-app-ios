//
//  MainViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt
import TangemLocalization
import TangemUI
import struct TangemUIUtils.ConfirmationDialogViewModel
import TangemFoundation
import TangemAccessibilityIdentifiers

final class MainViewModel: ObservableObject {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.mainBottomSheetUIManager) private var mainBottomSheetUIManager: MainBottomSheetUIManager
    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: any FloatingSheetPresenter
    @Injected(\.apiListProvider) private var apiListProvider: APIListProvider
    @Injected(\.wcService) private var wcService: WCService
    @Injected(\.yieldModuleNetworkManager) private var yieldModuleNetworkManager: YieldModuleNetworkManager

    // MARK: - ViewState

    @Published var pages: [MainUserWalletPageBuilder] = []
    @Published var selectedCardIndex = 0
    @Published var isHorizontalScrollDisabled = false
    @Published var confirmationDialog: ConfirmationDialogViewModel?

    let swipeDiscoveryAnimationTrigger = CardsInfoPagerSwipeDiscoveryAnimationTrigger()

    private(set) lazy var refreshScrollViewStateObject: RefreshScrollViewStateObject = .init(
        settings: .init(stopRefreshingDelay: 1, refreshTaskTimeout: 120), // 2 minutes
        refreshable: { [weak self] in
            await self?.onPullToRefresh()
        }
    )

    // MARK: - Dependencies

    private let swipeDiscoveryHelper: WalletSwipeDiscoveryHelper
    private let mainUserWalletPageBuilderFactory: MainUserWalletPageBuilderFactory
    private let pushNotificationsAvailabilityProvider: PushNotificationsAvailabilityProvider
    private weak var coordinator: MainRoutable?

    // MARK: - Internal state

    private let nftFeatureLifecycleHandler: NFTFeatureLifecycleHandling

    private var shouldDelayBottomSheetVisibility = true
    private var isLoggingOut = false

    private var bag: Set<AnyCancellable> = []

    // MARK: - Initializers

    init(
        coordinator: MainRoutable,
        swipeDiscoveryHelper: WalletSwipeDiscoveryHelper,
        mainUserWalletPageBuilderFactory: MainUserWalletPageBuilderFactory,
        pushNotificationsAvailabilityProvider: PushNotificationsAvailabilityProvider
    ) {
        self.coordinator = coordinator
        self.swipeDiscoveryHelper = swipeDiscoveryHelper
        self.mainUserWalletPageBuilderFactory = mainUserWalletPageBuilderFactory
        self.pushNotificationsAvailabilityProvider = pushNotificationsAvailabilityProvider
        nftFeatureLifecycleHandler = NFTFeatureLifecycleHandler()

        pages = mainUserWalletPageBuilderFactory.createPages(
            from: userWalletRepository.models,
            lockedUserWalletDelegate: self,
            singleWalletContentDelegate: self,
            multiWalletContentDelegate: self,
            nftLifecycleHandler: nftFeatureLifecycleHandler
        )

        assert(pages.count == userWalletRepository.models.count, "Number of pages must be equal to number of UserWalletModels")

        bind()
    }

    convenience init(
        selectedUserWalletId: UserWalletId,
        coordinator: MainRoutable,
        swipeDiscoveryHelper: WalletSwipeDiscoveryHelper,
        mainUserWalletPageBuilderFactory: MainUserWalletPageBuilderFactory,
        pushNotificationsAvailabilityProvider: PushNotificationsAvailabilityProvider
    ) {
        self.init(
            coordinator: coordinator,
            swipeDiscoveryHelper: swipeDiscoveryHelper,
            mainUserWalletPageBuilderFactory: mainUserWalletPageBuilderFactory,
            pushNotificationsAvailabilityProvider: pushNotificationsAvailabilityProvider
        )

        if let selectedIndex = pages.firstIndex(where: { $0.id == selectedUserWalletId }) {
            selectedCardIndex = selectedIndex
        }
    }

    // MARK: - Internal functions

    func openDetails() {
        coordinator?.openDetails()
    }

    /// Handles `SwiftUI.View.onAppear(perform:)`.
    func onViewAppear() {
        if !isLoggingOut {
            var analyticsParameters: [Analytics.ParameterKey: Analytics.ParameterValue] = [
                .appTheme: AppSettings.shared.appTheme.analyticsParamValue,
            ]

            if let userWalletModel = userWalletRepository.selectedModel {
                let walletType = Analytics.ParameterValue.seedState(for: userWalletModel.hasImportedWallets)
                analyticsParameters[.walletType] = walletType
            }

            Analytics.log(.mainScreenOpened, params: analyticsParameters)
        }

        updateYieldMarkets()

        swipeDiscoveryHelper.scheduleSwipeDiscoveryIfNeeded()
        openPushNotificationsAuthorizationIfNeeded()
    }

    /// Handles `SwiftUI.View.onDisappear(perform:)`.
    func onViewDisappear() {
        swipeDiscoveryHelper.cancelScheduledSwipeDiscovery()
        coordinator?.resignHandlingIncomingActions()
    }

    /// Handles `UIKit.UIViewController.viewDidAppear(_:)`.
    func onDidAppear() {
        // The application is already in a locked state, so no attempts to show bottom sheet should be made
        guard !isLoggingOut else {
            return
        }

        let uiManager = mainBottomSheetUIManager
        // On a `cold start` (e.g., after launching the app or after coming back from the background in a `locked` state:
        // in both cases a new VM is created), the bottom sheet should become visible with some delay to prevent it from
        // being placed over the authorization screen.
        // This is a workaround until [REDACTED_INFO] is implemented.
        if shouldDelayBottomSheetVisibility {
            shouldDelayBottomSheetVisibility = false
            DispatchQueue.main.asyncAfter(deadline: .now() + Constants.bottomSheetVisibilityColdStartDelay) {
                uiManager.show()
            }
        } else {
            uiManager.show()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.coordinator?.beginHandlingIncomingActions()
        }
    }

    func onPageChange(dueTo reason: CardsInfoPageChangeReason) {
        guard reason == .byGesture else { return }

        if !AppSettings.shared.userDidSwipeWalletsOnMainScreen {
            AppSettings.shared.userDidSwipeWalletsOnMainScreen = true
        }
    }

    func updateIsBackupAllowed() {
        // [REDACTED_TODO_COMMENT]
    }

    func didTapEditWallet() {
        Analytics.log(.buttonEditWalletTapped)

        if let selectedModel = userWalletRepository.selectedModel,
           let alert = AlertBuilder.makeWalletRenamingAlert(userWalletModel: selectedModel, userWalletRepository: userWalletRepository) {
            AppPresenter.shared.show(alert)
        }
    }

    // MARK: - User wallets pages management

    private func addNewPage(for userWalletModel: UserWalletModel) {
        let newPage = mainUserWalletPageBuilderFactory.createPage(
            for: userWalletModel,
            lockedUserWalletDelegate: self,
            singleWalletContentDelegate: self,
            multiWalletContentDelegate: self,
            nftLifecycleHandler: nftFeatureLifecycleHandler
        )

        let newPageIndex = pages.count
        pages.append(newPage)
        selectedCardIndex = newPageIndex
    }

    private func removePages(with userWalletIds: [UserWalletId]) {
        pages.removeAll { userWalletIds.contains($0.id) }

        guard
            let newSelectedId = userWalletRepository.selectedModel?.userWalletId,
            let index = pages.firstIndex(where: { $0.id == newSelectedId })
        else {
            return
        }

        selectedCardIndex = index
    }

    private func recreatePages() {
        pages = mainUserWalletPageBuilderFactory.createPages(
            from: userWalletRepository.models,
            lockedUserWalletDelegate: self,
            singleWalletContentDelegate: self,
            multiWalletContentDelegate: self,
            nftLifecycleHandler: nftFeatureLifecycleHandler
        )
    }

    // MARK: - Private functions

    private func bind() {
        $selectedCardIndex
            .dropFirst()
            .withWeakCaptureOf(self)
            .sink { viewModel, newIndex in
                guard let userWalletId = viewModel.pages[safe: newIndex]?.id else {
                    return
                }

                if viewModel.userWalletRepository.selectedModel?.userWalletId != userWalletId {
                    viewModel.userWalletRepository.select(userWalletId: userWalletId)
                }
            }
            .store(in: &bag)

        $selectedCardIndex
            .removeDuplicates()
            .prepend(-1) // A dummy value to trigger initial index change event
            .pairwise()
            .withWeakCaptureOf(self)
            .sink { viewModel, input in
                let (previousCardIndex, currentCardIndex) = input
                viewModel.pages[safe: previousCardIndex]?.onPageDisappear()
                viewModel.pages[safe: currentCardIndex]?.onPageAppear()
            }
            .store(in: &bag)

        userWalletRepository.eventProvider
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                guard let self else { return }

                switch event {
                case .unlocked:
                    recreatePages()
                case .locked:
                    isLoggingOut = true
                case .inserted(let userWalletId):
                    if let userWalletModel = userWalletRepository.models[userWalletId] {
                        addNewPage(for: userWalletModel)
                    }
                case .unlockedWallet(let userWalletId):
                    userWalletUnlocked(userWalletId: userWalletId)
                case .deleted(let userWalletIds):
                    // This model is alive for enough time to receive the "deleted" event
                    // after the last model has been removed and the application has been logged out
                    if userWalletRepository.models.isEmpty {
                        return
                    }
                    removePages(with: userWalletIds)
                    swipeDiscoveryHelper.reset()
                case .selected:
                    break
                }
            }
            .store(in: &bag)

        // We need to check if some pages are missing body model. This can happen due to not loaded API list
        // In this case we need to recreate this pages after API list loaded and WalletModelsManager publishes list of models
        let indexesToRecreate: [Int] = pages.indexed().compactMap { $1.missingBodyModel ? $0 : nil }
        if indexesToRecreate.isNotEmpty {
            // accounts_fixes_needed_main
            let walletModelPublishers = indexesToRecreate.map { userWalletRepository.models[$0].walletModelsManager.walletModelsPublisher }
            walletModelPublishers.combineLatest()
                .combineLatest(apiListProvider.apiListPublisher)
                .receive(on: DispatchQueue.main)
                .withWeakCaptureOf(self)
                .sink { viewModel, tuple in
                    let (_, apiList) = tuple

                    if apiList.isEmpty {
                        return
                    }

                    var currentPages = viewModel.pages
                    for (index, page) in currentPages.indexed() {
                        // Double check that body model is still missing
                        guard
                            page.missingBodyModel,
                            index < viewModel.userWalletRepository.models.count
                        else {
                            continue
                        }

                        let userWalletModel = viewModel.userWalletRepository.models[index]
                        let updatedPage = viewModel.mainUserWalletPageBuilderFactory.createPage(
                            for: userWalletModel,
                            lockedUserWalletDelegate: viewModel,
                            singleWalletContentDelegate: viewModel,
                            multiWalletContentDelegate: viewModel,
                            nftLifecycleHandler: viewModel.nftFeatureLifecycleHandler
                        )

                        if updatedPage.missingBodyModel {
                            continue
                        }

                        currentPages[index] = updatedPage
                    }

                    viewModel.pages = currentPages
                }
                .store(in: &bag)
        }

        wcService.transactionRequestPublisher
            .receiveOnMain()
            .sink { [coordinator, floatingSheetPresenter] transactionHandleResult in
                MainActor.assumeIsolated {
                    switch transactionHandleResult {
                    case .success(let transactionData):
                        let sheetViewModel = WCTransactionViewModel(
                            transactionData: transactionData,
                            feeManager: CommonWCTransactionFeeManager(
                                feeRepository: CommonWCTransactionFeePreferencesRepository(dappName: transactionData.dAppData.name)
                            ),
                            analyticsLogger: CommonWalletConnectTransactionAnalyticsLogger()
                        )
                        coordinator?.show(floatingSheetViewModel: sheetViewModel)

                    case .failure(let error):
                        if let transactionRequestError = error as? WalletConnectTransactionRequestProcessingError,
                           let errorViewModel = WalletConnectModuleFactory.makeTransactionRequestProcessingErrorViewModel(
                               transactionRequestError,
                               closeAction: {
                                   floatingSheetPresenter.removeActiveSheet()
                               }
                           ) {
                            coordinator?.show(floatingSheetViewModel: errorViewModel)
                        } else {
                            coordinator?.show(toast: WalletConnectModuleFactory.makeGenericErrorToast(error))
                        }
                    }
                }
            }
            .store(in: &bag)
    }

    private func openPushNotificationsAuthorizationIfNeeded() {
        guard pushNotificationsAvailabilityProvider.isAvailable else {
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.pushNotificationAuthorizationRequestDelay) { [weak self] in
            self?.coordinator?.openPushNotificationsAuthorization()
        }
    }

    @MainActor
    private func onPullToRefresh() async {
        defer {
            isHorizontalScrollDisabled = false
        }

        isHorizontalScrollDisabled = true

        guard
            let selectedUserWalletID = userWalletRepository.selectedModel?.userWalletId,
            let index = pages.firstIndex(where: { $0.id == selectedUserWalletID })
        else {
            return
        }

        let page = pages[index]

        switch page {
        case .singleWallet(_, _, let viewModel):
            await viewModel?.onPullToRefresh()
        case .multiWallet(_, _, let viewModel):
            await viewModel.onPullToRefresh()
        case .lockedWallet:
            break
        case .visaWallet(_, _, let viewModel):
            await viewModel.onPullToRefresh()
        }

        updateYieldMarkets(force: true)
    }
}

// MARK: - Unlocking

private extension MainViewModel {
    func userWalletUnlocked(userWalletId: UserWalletId) {
        guard let index = pages.firstIndex(where: { $0.id == userWalletId }) else {
            return
        }

        guard let userWalletModel = userWalletRepository.models[userWalletId] else {
            return
        }

        let page = mainUserWalletPageBuilderFactory.createPage(
            for: userWalletModel,
            lockedUserWalletDelegate: self,
            singleWalletContentDelegate: self,
            multiWalletContentDelegate: self,
            nftLifecycleHandler: nftFeatureLifecycleHandler
        )

        pages[index] = page
    }
}

// MARK: - Navigation

extension MainViewModel: MainLockedUserWalletDelegate {
    func openTroubleshooting(confirmationDialog: ConfirmationDialogViewModel) {
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.scanTroubleshootingDelay) {
            self.confirmationDialog = confirmationDialog
        }
    }

    func openMail(with dataCollector: EmailDataCollector, recipient: String, emailType: EmailType) {
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.feedbackRequestDelay) { [weak self] in
            self?.coordinator?.openMail(with: dataCollector, emailType: emailType, recipient: recipient)
        }
    }

    func openScanCardManual() {
        coordinator?.openScanCardManual()
    }
}

extension MainViewModel: MultiWalletMainContentDelegate {
    func displayAddressCopiedToast() {
        Toast(
            view: SuccessToast(text: Localization.walletNotificationAddressCopied)
                .accessibilityIdentifier(ActionButtonsAccessibilityIdentifiers.addressCopiedToast)
        )
        .present(
            layout: .top(padding: 12),
            type: .temporary()
        )
    }
}

extension MainViewModel: SingleWalletMainContentDelegate {
    func present(confirmationDialog: ConfirmationDialogViewModel) {
        self.confirmationDialog = confirmationDialog
    }
}

// MARK: - WalletSwipeDiscoveryHelperDelegate protocol conformance

extension MainViewModel: WalletSwipeDiscoveryHelperDelegate {
    func numberOfWallets(_ discoveryHelper: WalletSwipeDiscoveryHelper) -> Int {
        return pages.count
    }

    func userDidSwipeWallets(_ discoveryHelper: WalletSwipeDiscoveryHelper) -> Bool {
        return AppSettings.shared.userDidSwipeWalletsOnMainScreen
    }

    func helperDidTriggerSwipeDiscoveryAnimation(_ discoveryHelper: WalletSwipeDiscoveryHelper) {
        swipeDiscoveryAnimationTrigger.triggerDiscoveryAnimation()
    }
}

// MARK: - Yield module

extension MainViewModel {
    func updateYieldMarkets(force: Bool = false) {
        if force || yieldModuleNetworkManager.markets.isEmpty {
            yieldModuleNetworkManager.updateMarkets()
        }
    }
}

// MARK: - Constants

private extension MainViewModel {
    private enum Constants {
        /// A small delay for animated addition of newly inserted wallet(s) after the main view becomes visible.
        static let pendingWalletsInsertionDelay = 1.0
        static let feedbackRequestDelay = 0.7
        static let scanTroubleshootingDelay = 0.5
        static let pushNotificationAuthorizationRequestDelay = 0.5
        // [REDACTED_TODO_COMMENT]
        static let bottomSheetVisibilityColdStartDelay = 0.5
    }
}
