//
//  MainViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI
import Combine
import CombineExt

final class MainViewModel: ObservableObject {
    private typealias UserWalletIdData = Data

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @InjectedWritable(\.mainBottomSheetVisibility) private var bottomSheetVisibility: MainBottomSheetVisibility

    // MARK: - ViewState

    @Published var pages: [MainUserWalletPageBuilder] = []
    @Published var selectedCardIndex = 0
    @Published var isHorizontalScrollDisabled = false
    @Published var showAddressCopiedToast = false
    @Published var actionSheet: ActionSheetBinder?

    @Published var unlockWalletBottomSheetViewModel: UnlockUserWalletBottomSheetViewModel?
    @Published var rateAppBottomSheetViewModel: RateAppBottomSheetViewModel?
    @Published var isAppStoreReviewRequested = false

    let swipeDiscoveryAnimationTrigger = CardsInfoPagerSwipeDiscoveryAnimationTrigger()

    var isMainBottomSheetEnabled: Bool { FeatureProvider.isAvailable(.mainScreenBottomSheet) }

    // MARK: - Dependencies

    private let mainUserWalletPageBuilderFactory: MainUserWalletPageBuilderFactory
    private let rateAppService: RateAppService
    private let swipeDiscoveryHelper: WalletSwipeDiscoveryHelper
    private weak var coordinator: MainRoutable?

    // MARK: - Internal state

    private var pendingUserWalletIdsToUpdate: Set<UserWalletIdData> = []
    private var pendingUserWalletModelsToAdd: [UserWalletModel] = []
    private var shouldRecreatePagesAfterAddingPendingWalletModels = false

    private let notificationInputsSubject: CurrentValueSubject<[UserWalletIdData: [NotificationViewInput]], Never> = .init([:])
    private let loadedBalancesSubject: CurrentValueSubject<[UserWalletIdData: Bool], Never> = .init([:])

    private var isLoggingOut = false

    private var totalBalanceSubscriptions: [UserWalletIdData: AnyCancellable] = [:]
    private var bag: Set<AnyCancellable> = []

    // MARK: - Initializers

    init(
        coordinator: MainRoutable,
        rateAppService: RateAppService,
        swipeDiscoveryHelper: WalletSwipeDiscoveryHelper,
        mainUserWalletPageBuilderFactory: MainUserWalletPageBuilderFactory
    ) {
        self.coordinator = coordinator
        self.rateAppService = rateAppService
        self.swipeDiscoveryHelper = swipeDiscoveryHelper
        self.mainUserWalletPageBuilderFactory = mainUserWalletPageBuilderFactory

        pages = mainUserWalletPageBuilderFactory.createPages(
            from: userWalletRepository.models,
            lockedUserWalletDelegate: self,
            singleWalletContentDelegate: self,
            multiWalletContentDelegate: self
        )

        bind()
        subscribeToTotalBalanceUpdates(userWalletModels: userWalletRepository.models)
    }

    convenience init(
        selectedUserWalletId: UserWalletId,
        coordinator: MainRoutable,
        rateAppService: RateAppService,
        swipeDiscoveryHelper: WalletSwipeDiscoveryHelper,
        mainUserWalletPageBuilderFactory: MainUserWalletPageBuilderFactory
    ) {
        self.init(
            coordinator: coordinator,
            rateAppService: rateAppService,
            swipeDiscoveryHelper: swipeDiscoveryHelper,
            mainUserWalletPageBuilderFactory: mainUserWalletPageBuilderFactory
        )

        if let selectedIndex = pages.firstIndex(where: { $0.id == selectedUserWalletId }) {
            selectedCardIndex = selectedIndex
        }
    }

    // MARK: - Internal functions

    func openDetails() {
        let userWalletModel = userWalletRepository.models[selectedCardIndex]

        if userWalletModel.isUserWalletLocked {
            openUnlockUserWalletBottomSheet(for: userWalletModel)
            return
        }

        coordinator?.openDetails(for: userWalletModel)
    }

    func onViewAppear() {
        Analytics.log(.mainScreenOpened)

        bottomSheetVisibility.show()

        addPendingUserWalletModelsIfNeeded { [weak self] in
            self?.swipeDiscoveryHelper.scheduleSwipeDiscoveryIfNeeded()
        }

        requestRateApp(notificationInputs: notificationInputsSubject.value, loadedBalances: loadedBalancesSubject.value)
    }

    func onViewDisappear() {
        bottomSheetVisibility.hide()
        swipeDiscoveryHelper.cancelScheduledSwipeDiscovery()
    }

    func onPullToRefresh(completionHandler: @escaping RefreshCompletionHandler) {
        Analytics.log(.mainRefreshed)

        isHorizontalScrollDisabled = true
        let completion = { [weak self] in
            self?.isHorizontalScrollDisabled = false
            completionHandler()
        }
        let page = pages[selectedCardIndex]

        switch page {
        case .singleWallet(_, _, let viewModel):
            viewModel.onPullToRefresh(completionHandler: completion)
        case .multiWallet(_, _, let viewModel):
            viewModel.onPullToRefresh(completionHandler: completion)
        case .lockedWallet:
            completion()
        case .visaWallet(_, _, let viewModel):
            viewModel.onPullToRefresh(completionHandler: completion)
        }
    }

    func onPageChange(dueTo reason: CardsInfoPageChangeReason) {
        guard reason == .byGesture else { return }

        Analytics.log(.mainScreenWalletChangedBySwipe)

        if !AppSettings.shared.userDidSwipeWalletsOnMainScreen {
            AppSettings.shared.userDidSwipeWalletsOnMainScreen = true
        }
    }

    func updateIsBackupAllowed() {
        // [REDACTED_TODO_COMMENT]
    }

    func didTapEditWallet() {
        Analytics.log(.buttonEditWalletTapped)

        guard let userWallet = userWalletRepository.selectedModel?.userWallet else { return }

        let alert = AlertBuilder.makeAlertControllerWithTextField(
            title: Localization.userWalletListRenamePopupTitle,
            fieldPlaceholder: Localization.userWalletListRenamePopupPlaceholder,
            fieldText: userWallet.name
        ) { [weak self] newName in
            guard userWallet.name != newName else { return }

            var newUserWallet = userWallet
            newUserWallet.name = newName

            self?.userWalletRepository.save(newUserWallet)
        }

        AppPresenter.shared.show(alert)
    }

    func didTapDeleteWallet() {
        Analytics.log(.buttonDeleteWalletTapped)

        let sheet = ActionSheet(
            title: Text(Localization.userWalletListDeletePrompt),
            buttons: [
                .destructive(Text(Localization.commonDelete), action: weakify(self, forFunction: MainViewModel.didConfirmWalletDeletion)),
                .cancel(Text(Localization.commonCancel)),
            ]
        )
        actionSheet = ActionSheetBinder(sheet: sheet)
    }

    func didConfirmWalletDeletion() {
        guard
            let userWalletId = userWalletRepository.selectedUserWalletId,
            let userWalletModel = userWalletRepository.models.first(where: { $0.userWalletId.value == userWalletId })
        else {
            return
        }

        userWalletRepository.delete(userWalletModel.userWalletId, logoutIfNeeded: true)
    }

    // MARK: - User wallets pages management

    /// Marks the given user wallet as 'dirty' (needs to be updated).
    private func setNeedsUpdateUserWallet(_ userWallet: UserWallet) {
        pendingUserWalletIdsToUpdate.insert(userWallet.userWalletId)
    }

    /// Checks if the given user wallet is 'dirty' (needs to be updated).
    private func userWalletAwaitsPendingUpdate(_ userWallet: UserWallet) -> Bool {
        return pendingUserWalletIdsToUpdate.contains(userWallet.userWalletId)
    }

    /// Postpones the creation of a new page for a given user wallet model if its
    /// user wallet is marked for update. Otherwise, the new page is added immediately.
    private func processUpdatedUserWalletModel(_ userWalletModel: UserWalletModel) {
        if userWalletAwaitsPendingUpdate(userWalletModel.userWallet) {
            pendingUserWalletModelsToAdd.append(userWalletModel)
        } else {
            addNewPage(for: userWalletModel)
        }
    }

    /// Adds new pages for pending user wallet models and performs the required clean-up
    /// of 'dirty' (need to be updated) user wallets.
    private func addPendingUserWalletModelsIfNeeded(completion: @escaping () -> Void) {
        if pendingUserWalletModelsToAdd.isEmpty {
            completion()
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.pendingWalletsInsertionDelay) { [weak self] in
            defer { completion() }

            guard let self = self else { return }

            let userWalletModels = pendingUserWalletModelsToAdd
            pendingUserWalletModelsToAdd.removeAll()

            var processedUserWalletIds: Set<UserWalletIdData> = []
            for userWalletModel in userWalletModels {
                processedUserWalletIds.insert(userWalletModel.userWallet.userWalletId)
                addNewPage(for: userWalletModel)
            }
            pendingUserWalletIdsToUpdate.subtract(processedUserWalletIds)

            if shouldRecreatePagesAfterAddingPendingWalletModels {
                shouldRecreatePagesAfterAddingPendingWalletModels = false
                recreatePages()
            }
        }
    }

    private func addNewPage(for userWalletModel: UserWalletModel) {
        // [REDACTED_TODO_COMMENT]
        // We need this check to prevent adding new pages after each
        // UserWalletModel update in `CommonUserWalletRepository`.
        // The problem itself not in `update` event from repository but
        // in `inserted` event, which is sending `UserWallet` instead of `UserWalletModel`
        if pages.contains(where: { $0.id == userWalletModel.userWalletId }) {
            return
        }

        guard
            let newPage = mainUserWalletPageBuilderFactory.createPage(
                for: userWalletModel,
                lockedUserWalletDelegate: self,
                singleWalletContentDelegate: self,
                multiWalletContentDelegate: self
            )
        else {
            return
        }

        let newPageIndex = pages.count
        pages.append(newPage)
        selectedCardIndex = newPageIndex

        subscribeToTotalBalanceUpdates(userWalletModel: userWalletModel)
    }

    private func removePages(with userWalletIds: [UserWalletIdData]) {
        pages.removeAll { userWalletIds.contains($0.id.value) }
        totalBalanceSubscriptions.removeAll { userWalletIds.contains($0.key) }
        notificationInputsSubject.value.removeAll { userWalletIds.contains($0.key) }
        loadedBalancesSubject.value.removeAll { userWalletIds.contains($0.key) }

        guard
            let newSelectedId = userWalletRepository.selectedUserWalletId,
            let index = pages.firstIndex(where: { $0.id.value == newSelectedId })
        else {
            return
        }

        selectedCardIndex = index
    }

    /// Postpones pages re-creation if a given user wallet is marked for update.
    /// Otherwise, re-creates pages immediately.
    private func recreatePagesIfNeeded(for userWallet: UserWallet) {
        if userWalletAwaitsPendingUpdate(userWallet) {
            shouldRecreatePagesAfterAddingPendingWalletModels = true
        } else {
            recreatePages()
        }
    }

    private func recreatePages() {
        pages = mainUserWalletPageBuilderFactory.createPages(
            from: userWalletRepository.models,
            lockedUserWalletDelegate: self,
            singleWalletContentDelegate: self,
            multiWalletContentDelegate: self
        )

        subscribeToTotalBalanceUpdates(userWalletModels: userWalletRepository.models)
    }

    // MARK: - Private functions

    private func bind() {
        let selectedCardIndexPublisher = $selectedCardIndex
            .removeDuplicates()
            .share(replay: 1)

        selectedCardIndexPublisher
            .dropFirst()
            .sink { [weak self] newIndex in
                guard let userWalletId = self?.pages[newIndex].id else {
                    return
                }

                Analytics.log(.walletOpened)

                self?.userWalletRepository.setSelectedUserWalletId(
                    userWalletId.value,
                    unlockIfNeeded: false,
                    reason: .userSelected
                )
            }
            .store(in: &bag)

        selectedCardIndexPublisher
            .combineLatest(notificationInputsSubject.removeDuplicates(), loadedBalancesSubject.removeDuplicates())
            .withWeakCaptureOf(self)
            .sink { input in
                let (viewModel, (_, notificationInputs, loadedBalances)) = input
                viewModel.requestRateApp(notificationInputs: notificationInputs, loadedBalances: loadedBalances)
            }
            .store(in: &bag)

        userWalletRepository.eventProvider
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                guard let self else { return }

                switch event {
                case .locked:
                    isLoggingOut = true
                case .scan:
                    // [REDACTED_TODO_COMMENT]
                    break
                case .inserted(let userWallet):
                    setNeedsUpdateUserWallet(userWallet)
                case .updated(let userWalletModel):
                    processUpdatedUserWalletModel(userWalletModel)
                case .deleted(let userWalletIds):
                    // This model is alive for enough time to receive the "deleted" event
                    // after the last model has been removed and the application has been logged out
                    if isLoggingOut == true {
                        return
                    }
                    removePages(with: userWalletIds)
                    swipeDiscoveryHelper.reset()
                case .selected(let userWallet, let reason):
                    if reason == .inserted {
                        recreatePagesIfNeeded(for: userWallet)
                    }
                case .replaced(let userWallet):
                    recreatePagesIfNeeded(for: userWallet)
                case .biometryUnlocked:
                    break
                }
            }
            .store(in: &bag)
    }

    private func subscribeToTotalBalanceUpdates(userWalletModels: [UserWalletModel]) {
        userWalletModels.forEach(subscribeToTotalBalanceUpdates(userWalletModel:))
    }

    private func subscribeToTotalBalanceUpdates(userWalletModel: UserWalletModel) {
        let identifier = userWalletModel.userWalletId.value
        totalBalanceSubscriptions[identifier] = userWalletModel
            .totalBalancePublisher()
            .withWeakCaptureOf(self)
            .handleEvents(receiveOutput: { viewModel, totalBalance in
                viewModel.rateAppService.registerBalances(of: userWalletModel.walletModelsManager.walletModels)
            })
            .map { $0.1.value != nil }
            .withLatestFrom(loadedBalancesSubject.removeDuplicates()) { isBalanceLoaded, loadedBalances in
                var loadedBalances = loadedBalances
                loadedBalances[identifier] = isBalanceLoaded
                return loadedBalances
            }
            .subscribe(loadedBalancesSubject)
    }

    private func requestRateApp(
        notificationInputs: [UserWalletIdData: [NotificationViewInput]],
        loadedBalances: [UserWalletIdData: Bool]
    ) {
        let pageInfos = pages.map { page in
            return RateAppRequest.PageInfo(
                isLocked: page.isLockedWallet,
                isSelected: page.id == userWalletRepository.selectedModel?.userWalletId,
                isBalanceLoaded: loadedBalances[page.id.value, default: false],
                displayedNotifications: notificationInputs[page.id.value, default: []]
            )
        }
        rateAppService.requestRateAppIfAvailable(with: .init(pageInfos: pageInfos))
    }

    private func log(_ message: String) {
        AppLog.shared.debug("[Main V2] \(message)")
    }
}

// MARK: - Navigation

extension MainViewModel: MainLockedUserWalletDelegate {
    func openUnlockUserWalletBottomSheet(for userWalletModel: UserWalletModel) {
        unlockWalletBottomSheetViewModel = .init(
            userWalletModel: userWalletModel,
            delegate: self
        )
    }
}

extension MainViewModel: UnlockUserWalletBottomSheetDelegate {
    func unlockedWithBiometry() {
        unlockWalletBottomSheetViewModel = nil
        recreatePages()
    }

    func userWalletUnlocked(_ userWalletModel: UserWalletModel) {
        guard
            let index = pages.firstIndex(where: { $0.id == userWalletModel.userWalletId }),
            let page = mainUserWalletPageBuilderFactory.createPage(
                for: userWalletModel,
                lockedUserWalletDelegate: self,
                singleWalletContentDelegate: self,
                multiWalletContentDelegate: self
            )
        else {
            return
        }

        pages[index] = page
        unlockWalletBottomSheetViewModel = nil
    }

    func openMail(with dataCollector: EmailDataCollector, recipient: String, emailType: EmailType) {
        unlockWalletBottomSheetViewModel = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.feedbackRequestDelay) { [weak self] in
            self?.coordinator?.openMail(with: dataCollector, emailType: emailType, recipient: recipient)
        }
    }
}

extension MainViewModel: MultiWalletMainContentDelegate {
    func displayAddressCopiedToast() {
        showAddressCopiedToast = true
    }
}

extension MainViewModel: SingleWalletMainContentDelegate {
    func present(actionSheet: ActionSheetBinder) {
        self.actionSheet = actionSheet
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

// MARK: - MainNotificationsObserver protocol conformance

extension MainViewModel: MainNotificationsObserver {
    func didChangeNotificationInputs(_ inputs: [NotificationViewInput], for userWalletId: UserWalletId) {
        notificationInputsSubject.value[userWalletId.value] = inputs
    }
}

// MARK: - RateAppServiceDelegate protocol conformance

extension MainViewModel: RateAppServiceDelegate {
    func rateAppService(
        _ service: RateAppService,
        didRequestRateAppWithCompletionHandler completionHandler: @escaping (RateAppResult) -> Void
    ) {
        rateAppBottomSheetViewModel = RateAppBottomSheetViewModel(onInteraction: completionHandler)
    }

    func rateAppService(_ service: RateAppService, didRequestOpenMailWithEmailType emailType: EmailType) {
        rateAppBottomSheetViewModel = nil

        guard let userWallet = userWalletRepository.selectedModel else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.feedbackRequestDelay) { [weak self] in
            let collector = NegativeFeedbackDataCollector(userWalletEmailData: userWallet.emailData)
            let recipient = userWallet.emailConfig?.recipient ?? EmailConfig.default.recipient
            self?.coordinator?.openMail(with: collector, emailType: emailType, recipient: recipient)
        }
    }

    func requestAppStoreReviewForRateAppService(_ service: RateAppService) {
        rateAppBottomSheetViewModel = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.feedbackRequestDelay) { [weak self] in
            self?.isAppStoreReviewRequested = true
        }
    }
}

// MARK: - Constants

private extension MainViewModel {
    private enum Constants {
        /// A small delay for animated addition of newly inserted wallet(s) after the main view becomes visible.
        static let pendingWalletsInsertionDelay = 1.0
        static let feedbackRequestDelay = 0.7
    }
}
