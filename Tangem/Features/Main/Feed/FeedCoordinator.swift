//
//  FeedCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemFoundation
import TangemLocalization
import TangemUI
import TangemUIUtils

final class FeedCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    @Published private(set) var rootViewModel: FeedViewModel?
    @Published var path: [FeedDestination] = [] {
        didSet {
            container?.setNavigationActive(path.isNotEmpty)
        }
    }

    @Published var presented: FeedDestination?
    @Published var cover: FeedCover?

    private(set) var container: (any FeedContainer)?

    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: FloatingSheetPresenter
    @Injected(\.floatingSheetPresentingStateProvider) private var sheetStateProvider: FloatingSheetPresentingStateProvider
    @Injected(\.alertPresenter) private var alertPresenter: AlertPresenter

    private weak var host: FeedHostRoutable?
    private var earnRouter: EarnFeedRouter?
    private weak var presentedWidgetSheet: AnyObject?
    private weak var accountCreationWallet: UserWalletModel?
    private var accountFormCompletion: (() -> Void)?
    private var pendingDestination: FeedDestination?
    private var bag = Set<AnyCancellable>()

    @MainActor
    private var isOpeningCollectibles = false

    required init(dismissAction: @escaping Action<Void>, popToRootAction: @escaping Action<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        container = options.container
        host = options.host

        let context = FeedContext(navigation: self, popToRootAction: popToRootAction)
        earnRouter = EarnFeedRouter(context: context)
        rootViewModel = FeedViewModelFactory().makeViewModel(
            context: context,
            container: options.container,
            widgetsRouter: self,
            canOpenHostScreens: options.host != nil,
            selection: options.selection
        )

        bind(to: options.container)
    }

    func apply(selection: FeedSelection) {
        dropRoutes()
        rootViewModel?.searchViewModel.reset()
        rootViewModel?.apply(selection: selection)
    }

    func accountFormDidDismiss() {
        let completion = accountFormCompletion
        accountFormCompletion = nil
        completion?()
    }

    func sheetDidFinishExpanding() {
        guard let pendingDestination else { return }
        self.pendingDestination = nil

        guard let container, container.isPresented, container.size == .full,
              path.isEmpty, presented == nil, cover == nil, presentedWidgetSheet == nil else { return }

        push(pendingDestination)
    }
}

// MARK: - Options

extension FeedCoordinator {
    struct Options {
        let container: any FeedContainer
        /// The screen the feed is shown on, for the destinations it cannot open itself. Absent where the feed
        /// stands on its own: a widget that exists only for that hand-off is left out rather than left dead.
        /// Add account stays either way — creating the account is its own errand, and only the step on to
        /// Manage tokens afterwards has nowhere to go.
        var host: FeedHostRoutable?
        var selection: FeedSelection?
    }
}

// MARK: - FeedNavigation

extension FeedCoordinator: FeedNavigation {
    func push(_ destination: FeedDestination) {
        pendingDestination = nil
        endEditing()
        path.append(destination)
    }

    func pop() {
        _ = path.popLast()
    }

    func present(_ destination: FeedDestination) {
        endEditing()
        presented = destination
    }

    func presentFullScreen(_ destination: FeedDestination, zoomingFrom source: FeedZoomSource) {
        guard cover == nil else {
            return
        }

        endEditing()
        cover = FeedCover(destination: destination, zoomSource: source)
    }

    func dismissPresented() {
        presented = nil
        cover = nil
    }

    /// Resign before leaving the feed, otherwise UIKit restores the search field as first responder on the way back.
    private func endEditing() {
        UIApplication.shared.endEditing()
    }
}

// MARK: - FeedWidgetsRoutable

extension FeedCoordinator: FeedWidgetsRoutable {
    func openPolymarketMain(wallet: UserWalletModel) {
        guard path.isEmpty else { return }

        container?.expand()

        let coordinator = PolymarketCoordinator(
            dismissAction: { [weak self] in self?.pop() },
            popToRootAction: popToRootAction
        )
        coordinator.start(with: .init(userWalletModel: wallet))

        push(.polymarket(coordinator))
    }

    func openCollectibles(wallets: [UserWalletModel], isRegionRestricted: Bool) {
        Task { @MainActor [weak self] in
            guard let self, path.isEmpty, presentedWidgetSheet == nil, let wallet = wallets.first else { return }

            guard wallets.count > 1 else {
                openCollectibles(for: wallet, isRegionRestricted: isRegionRestricted)
                return
            }

            presentWalletSelector(wallets: wallets) { [weak self] wallet in
                self?.openCollectibles(for: wallet, isRegionRestricted: isRegionRestricted)
            }
        }
    }

    func openForYou() {
        guard path.isEmpty, pendingDestination == nil else { return }

        let coordinator = ForYouCoordinator(
            dismissAction: { [weak self] _ in self?.pop() },
            popToRootAction: popToRootAction,
            routeOnTokenResolvedAction: { [weak self] resolution, source in
                self?.earnRouter?.routeOnTokenResolved(resolution, source: source)
            }
        )
        coordinator.start(with: .init())

        guard let container, container.size != .full else {
            push(.forYou(coordinator))
            return
        }

        pendingDestination = .forYou(coordinator)
        withAnimation {
            container.expand()
        }
    }

    func openEarn() {
        guard let tabs = rootViewModel?.tabsViewModel,
              let tab = tabs.tabs.first(where: { $0.kind == .earn }) else { return }

        rootViewModel?.searchViewModel.reset()
        tabs.requestTabSelection(tab)
    }

    func openTangemPay(_ entry: FeedTangemPayEntry) {
        host?.openTangemPay(entry: entry)
    }

    func openReferral(
        candidates: [FeedReferralWalletCandidate],
        candidatesPublisher: AnyPublisher<[FeedReferralWalletCandidate], Never>,
        resolveAvailableWallet: @escaping (UserWalletId) -> UserWalletModel?,
        onDismiss: @escaping (UserWalletId) -> Void
    ) {
        Task { @MainActor [weak self] in
            guard let self, presented == nil, presentedWidgetSheet == nil else { return }

            let availableCandidates = candidates.filter(\.isAvailable)
            guard let candidate = availableCandidates.first else { return }

            guard availableCandidates.count > 1 else {
                openReferral(for: candidate.wallet.userWalletId, resolveAvailableWallet: resolveAvailableWallet, onDismiss: onDismiss)
                return
            }

            let selector = FeedReferralWalletSelectorViewModel(
                candidates: candidates,
                candidatesPublisher: candidatesPublisher,
                onSelect: { [weak self] walletId in
                    Task { @MainActor [weak self] in
                        self?.openReferral(for: walletId, resolveAvailableWallet: resolveAvailableWallet, onDismiss: onDismiss)
                    }
                },
                close: { [weak self] in self?.dismissWidgetSheet() }
            )
            enqueueWidgetSheet(selector)
        }
    }

    func openAddAccount(candidates: [FeedAccountCandidate]) {
        Task { @MainActor [weak self] in
            guard let self, presented == nil, presentedWidgetSheet == nil, let candidate = candidates.first else { return }

            if candidates.count == 1 {
                openAccountCreation(for: candidate)
                return
            }

            presentWalletSelector(wallets: candidates.map(\.wallet)) { [weak self] wallet in
                guard let candidate = candidates.first(where: { $0.wallet.userWalletId == wallet.userWalletId }) else { return }

                self?.openAccountCreation(for: candidate)
            }
        }
    }
}

// MARK: - AddAccountTypeSelectorRoutable

extension FeedCoordinator: AddAccountTypeSelectorRoutable {
    func openCryptoAccountForm(accountModelsManager: any AccountModelsManager, userWalletConfig: UserWalletConfig) {
        Task { @MainActor in
            guard presented == nil, validateAccountLimit(accountModelsManager: accountModelsManager) else { return }

            dismissWidgetSheet()

            let viewModel = AccountFormViewModel(
                flowType: .create(creator: CryptoAccountFormViewCreator(accountModelsManager: accountModelsManager)),
                coordinator: self
            )
            present(.accountForm(viewModel))
        }
    }

    func openJointAccountManagement(accountModelsManager: any AccountModelsManager, userWalletConfig: UserWalletConfig) {
        Task { @MainActor in
            guard presented == nil, validateAccountLimit(accountModelsManager: accountModelsManager) else { return }

            dismissWidgetSheet()

            let coordinator = JointAccountManagementCoordinator(
                dismissAction: { [weak self] _ in
                    guard let self, case .jointAccount = presented else { return }

                    dismissPresented()
                },
                popToRootAction: popToRootAction
            )
            coordinator.start(with: .creation(.init(accountModelsManager: accountModelsManager, userWalletConfig: userWalletConfig)))
            present(.jointAccount(coordinator))
        }
    }

    func dismissAddAccountTypeSelector() {
        Task { @MainActor in dismissWidgetSheet() }
    }
}

// MARK: - AccountFormViewModelRoutable

extension FeedCoordinator: AccountFormViewModelRoutable {
    func closeAccountForm(outcome: AccountFormOutcome) {
        guard case .accountForm = presented else { return }

        if case .completed(.crypto(let result, let createdAccount)) = outcome {
            accountFormCompletion = makeAccountFormCompletion(
                result: result,
                createdAccount: createdAccount,
                wallet: accountCreationWallet
            )
        }
        accountCreationWallet = nil
        dismissPresented()
    }
}

// MARK: - Widget sheets

@MainActor
private extension FeedCoordinator {
    func openReferral(
        for walletId: UserWalletId,
        resolveAvailableWallet: (UserWalletId) -> UserWalletModel?,
        onDismiss: @escaping (UserWalletId) -> Void
    ) {
        guard presented == nil, let wallet = resolveAvailableWallet(walletId) else { return }

        if presentedWidgetSheet != nil {
            dismissWidgetSheet()
        }

        let coordinator = ReferralCoordinator(
            dismissAction: { [weak self] _ in
                guard let self, case .referral = presented else { return }

                dismissPresented()
                onDismiss(wallet.userWalletId)
            },
            popToRootAction: popToRootAction
        )
        coordinator.start(with: .init(input: .init(
            userWalletId: wallet.userWalletId.value,
            supportedBlockchains: wallet.config.supportedBlockchains,
            accountModelsManager: wallet.accountModelsManager,
            tokenIconInfoBuilder: TokenIconInfoBuilder(),
            userWalletModel: wallet
        )))
        present(.referral(coordinator))
    }

    func validateAccountLimit(accountModelsManager: any AccountModelsManager) -> Bool {
        let accountsCount = AccountModelsAggregator(.crypto, .joint).models(from: accountModelsManager).count
        guard accountsCount < AccountModelUtils.maxNumberOfAccounts else {
            alertPresenter.present(alert: AccountEditErrorAlertBuilder.makeAlert(for: .tooManyAccounts))
            return false
        }

        return true
    }

    func openAccountCreation(for candidate: FeedAccountCandidate) {
        guard presented == nil, candidate.availability.isAvailable else { return }

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
        enqueueWidgetSheet(viewModel)
    }

    func openCollectibles(for wallet: UserWalletModel, isRegionRestricted: Bool) {
        guard !isOpeningCollectibles else { return }

        isOpeningCollectibles = true

        Task { @MainActor [weak self] in
            defer { self?.isOpeningCollectibles = false }

            guard let self else { return }

            let accountModel = wallet.collectiblesAccountModel()
            let outcome = await CollectiblesEntranceResolver.resolve(for: accountModel, isRegionRestricted: isRegionRestricted)

            guard container?.isPresented == true, path.isEmpty, presented == nil, presentedWidgetSheet == nil else {
                return
            }

            switch outcome {
            case .open(let destination):
                let coordinator = CollectiblesCoordinator(
                    dismissAction: { [weak self] in self?.dismissPresented() },
                    popToRootAction: popToRootAction
                )
                coordinator.start(with: .init(destination: destination, userWalletModel: wallet, accountModel: accountModel))

                present(.collectibles(coordinator))

            case .regionRestricted:
                let geoblock = CollectiblesGeoblockViewModel()
                enqueueWidgetSheet(geoblock)
            }
        }
    }

    func presentWalletSelector(wallets: [UserWalletModel], onSelect: @escaping @MainActor (UserWalletModel) -> Void) {
        let selector = AccountSelectorViewModel(
            userWalletModels: wallets,
            preferredDisplayMode: .wallets
        ) { [weak self] selection in
            Task { @MainActor [weak self] in
                guard let self else { return }

                dismissWidgetSheet()
                onSelect(selection.userWalletModel)
            }
        }
        let viewModel = WalletSelectorSheetViewModel(
            accountSelectorViewModel: selector,
            close: { [weak self] in self?.dismissWidgetSheet() }
        )
        enqueueWidgetSheet(viewModel)
    }

    func enqueueWidgetSheet(_ sheet: some FloatingSheetContentViewModel & AnyObject) {
        presentedWidgetSheet = sheet
        floatingSheetPresenter.enqueue(sheet: sheet)
    }

    func dismissWidgetSheet() {
        presentedWidgetSheet = nil
        floatingSheetPresenter.removeActiveSheet()
    }
}

// MARK: - Private

private extension FeedCoordinator {
    func bind(to container: any FeedContainer) {
        sheetStateProvider
            .hasPresentedSheetPublisher
            .filter { !$0 }
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { coordinator, _ in
                coordinator.presentedWidgetSheet = nil
            }
            .store(in: &bag)

        container
            .sizePublisher
            .withWeakCaptureOf(self)
            .sink { coordinator, size in
                if size != .full {
                    coordinator.pendingDestination = nil
                }

                // Keep search behind a child screen so Back can restore it after the sheet expands.
                guard size != .full, coordinator.path.isEmpty,
                      coordinator.presented == nil, coordinator.cover == nil else { return }

                coordinator.rootViewModel?.scrollCoordinator.reset()
                coordinator.rootViewModel?.searchViewModel.reset()
            }
            .store(in: &bag)

        container
            .dismissPublisher
            .withWeakCaptureOf(self)
            .sink { coordinator, _ in
                coordinator.dropRoutes()
            }
            .store(in: &bag)
    }

    /// Routes outlive a collapse — the collapsed sheet still shows the screen the user left open — but not the sheet
    /// itself: once it is gone, the screens it held go with it instead of living on until the main screen is rebuilt.
    func dropRoutes() {
        pendingDestination = nil
        guard path.isNotEmpty || presented != nil || cover != nil else {
            return
        }

        withTransaction(.withoutAnimations()) {
            path.removeAll()
            presented = nil
            cover = nil
            rootViewModel?.searchViewModel.reset()
        }
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
