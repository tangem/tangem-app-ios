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
            shtorkaStateObject.setNavigationActive(path.isNotEmpty)
        }
    }

    @Published var presented: FeedDestination?
    @Published var cover: FeedCover?

    let shtorkaStateObject = MainShtorkaStateObject()

    /// The feed's own views get the sheet narrowed down to what they may do with it, its view model to what it
    /// has to follow.
    var shtorkaReporting: any MainShtorkaReporting { shtorkaStateObject }
    var shtorkaActions: any MainShtorkaViewActionProvider { shtorkaStateObject }

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: FloatingSheetPresenter
    @Injected(\.alertPresenter) private var alertPresenter: AlertPresenter

    private weak var host: FeedHostRoutable?
    private var earnRouter: EarnFeedRouter?
    private weak var presentedWidgetSheet: AnyObject?
    private weak var accountCreationWallet: UserWalletModel?
    private var accountFormCompletion: (() -> Void)?
    private var bag = Set<AnyCancellable>()

    required init(dismissAction: @escaping Action<Void>, popToRootAction: @escaping Action<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        host = options.host
        let context = FeedContext(navigation: self, popToRootAction: popToRootAction)
        earnRouter = EarnFeedRouter(context: context)
        rootViewModel = FeedViewModelFactory().makeViewModel(
            context: context,
            shtorkaActions: shtorkaActions,
            widgetsRouter: self
        )

        bind()
    }

    func accountFormDidDismiss() {
        let completion = accountFormCompletion
        accountFormCompletion = nil
        completion?()
    }
}

// MARK: - Options

extension FeedCoordinator {
    struct Options {
        let host: FeedHostRoutable
    }
}

// MARK: - FeedNavigation

extension FeedCoordinator: FeedNavigation {
    func push(_ destination: FeedDestination) {
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
    func openForYou() {
        guard path.isEmpty else { return }

        shtorkaStateObject.expand()
        let coordinator = ForYouCoordinator(
            dismissAction: { [weak self] _ in self?.pop() },
            popToRootAction: popToRootAction,
            routeOnTokenResolvedAction: { [weak self] resolution, source in
                self?.earnRouter?.routeOnTokenResolved(resolution, source: source)
            }
        )
        coordinator.start(with: .init())
        push(.forYou(coordinator))
    }

    func openAddAccount(candidates: [FeedAccountCandidate]) {
        Task { @MainActor [weak self] in
            guard let self, presented == nil, presentedWidgetSheet == nil, let candidate = candidates.first else { return }

            if candidates.count == 1 {
                openAccountCreation(for: candidate)
                return
            }

            let selector = AccountSelectorViewModel(
                userWalletModels: candidates.map(\.wallet),
                preferredDisplayMode: .wallets
            ) { [weak self] selection in
                Task { @MainActor [weak self] in
                    guard let self,
                          let candidate = candidates.first(where: { $0.wallet.userWalletId == selection.userWalletModel.userWalletId }) else { return }

                    dismissWidgetSheet()
                    openAccountCreation(for: candidate)
                }
            }
            let viewModel = WalletSelectorSheetViewModel(
                accountSelectorViewModel: selector,
                close: { [weak self] in self?.dismissWidgetSheet() }
            )
            enqueueWidgetSheet(viewModel)
        }
    }
}

// MARK: - AddAccountTypeSelectorRoutable

extension FeedCoordinator: AddAccountTypeSelectorRoutable {
    func openCryptoAccountForm(accountModelsManager: any AccountModelsManager, userWalletConfig: UserWalletConfig) {
        Task { @MainActor in
            dismissWidgetSheet()
            guard presented == nil else { return }

            let viewModel = AccountFormViewModel(
                flowType: .create(creator: CryptoAccountFormViewCreator(accountModelsManager: accountModelsManager)),
                coordinator: self
            )
            present(.accountForm(viewModel))
        }
    }

    func openJointAccountManagement(accountModelsManager: any AccountModelsManager, userWalletConfig: UserWalletConfig) {
        Task { @MainActor in
            dismissWidgetSheet()
            guard presented == nil else { return }

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
            coordinator: self
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
    func bind() {
        shtorkaStateObject
            .$isPresented
            .filter { !$0 }
            .withWeakCaptureOf(self)
            .sink { coordinator, _ in
                coordinator.dropRoutes()
            }
            .store(in: &bag)
    }

    /// Routes outlive a collapse — the collapsed sheet still shows the screen the user left open — but not the sheet
    /// itself: once it is gone, the screens it held go with it instead of living on until the main screen is rebuilt.
    func dropRoutes() {
        guard path.isNotEmpty || presented != nil || cover != nil else {
            return
        }

        withTransaction(.withoutAnimations()) {
            path.removeAll()
            presented = nil
            cover = nil
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
