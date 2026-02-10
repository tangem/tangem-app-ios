//
//  ActionButtonsSwapCoordinator.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemUI

typealias ActionButtonsTokenSelectorViewModel = TokenSelectorViewModel<
    ActionButtonsTokenSelectorItem,
    ActionButtonsTokenSelectorItemBuilder
>

final class ActionButtonsSwapCoordinator: CoordinatorObject {
    let dismissAction: Action<ExpressCoordinator.DismissOptions?>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Injected

    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: FloatingSheetPresenter
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    // MARK: - Published

    @Published private(set) var viewType: ViewType?

    // MARK: - Private property

    private let expressTokensListAdapter: ExpressTokensListAdapter
    private let tokenSorter: TokenAvailabilitySorter
    private let userWalletModel: UserWalletModel
    private let yieldModuleNotificationInteractor: YieldModuleNoticeInteractor

    required init(
        expressTokensListAdapter: some ExpressTokensListAdapter,
        userWalletModel: some UserWalletModel,
        dismissAction: @escaping Action<ExpressCoordinator.DismissOptions?>,
        tokenSorter: some TokenAvailabilitySorter,
        yieldModuleNotificationInteractor: YieldModuleNoticeInteractor,
        popToRootAction: @escaping Action<PopToRootOptions> = { _ in }
    ) {
        self.tokenSorter = tokenSorter
        self.expressTokensListAdapter = expressTokensListAdapter
        self.userWalletModel = userWalletModel
        self.yieldModuleNotificationInteractor = yieldModuleNotificationInteractor
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        switch options {
        case .default:
            viewType = .legacy(ActionButtonsSwapViewModel(
                coordinator: self,
                userWalletModel: userWalletModel,
                sourceSwapTokenSelectorViewModel: makeTokenSelectorViewModel()
            ))
        case .new(let tokenSelectorViewModel):
            let marketsTokensViewModel = SwapMarketsTokensViewModel(
                searchProvider: CommonSwapMarketsSearchTokensProvider(tangemApiService: tangemApiService),
                configuration: .searchOnlyOnDemand
            )

            viewType = .new(
                AccountsAwareActionButtonsSwapViewModel(
                    tokenSelectorViewModel: tokenSelectorViewModel,
                    marketsTokensViewModel: marketsTokensViewModel,
                    coordinator: self,
                    tangemApiService: tangemApiService
                )
            )
        }
    }
}

// MARK: - Options

extension ActionButtonsSwapCoordinator {
    enum Options {
        case `default`
        case new(tokenSelectorViewModel: AccountsAwareTokenSelectorViewModel)
    }
}

// MARK: - ActionButtonsSwapRoutable

extension ActionButtonsSwapCoordinator: ActionButtonsSwapRoutable {
    func openExpress(input: ExpressDependenciesInput) {
        let factory = CommonExpressModulesFactory(input: input)
        let coordinator = ExpressCoordinator(
            factory: factory,
            dismissAction: dismissAction,
            popToRootAction: popToRootAction
        )

        coordinator.start(with: .default)
        viewType = .express(coordinator)
    }

    func dismiss() {
        ActionButtonsAnalyticsService.trackCloseButtonTap(source: .swap)
        dismiss(with: .none)
    }

    func showYieldNotificationIfNeeded(for walletModel: any WalletModel, completion: (() -> Void)?) {
        guard yieldModuleNotificationInteractor.shouldShowYieldModuleAlert(for: walletModel.tokenItem) else {
            completion.map { $0() }
            return
        }

        Task { @MainActor in
            let vm = YieldNoticeViewModel(tokenItem: walletModel.tokenItem) { [weak self] in
                self?.floatingSheetPresenter.removeActiveSheet()
                completion.map { $0() }
            }

            floatingSheetPresenter.enqueue(sheet: vm)
        }
    }
}

extension ActionButtonsSwapCoordinator: SwapTokenSelectorRoutable {
    func closeSwapTokenSelector() {}

    /// Opens the add-token flow for an external token selected from search results
    @MainActor
    func openAddTokenFlowForExpress(inputData: ExpressAddTokenInputData) {
        guard !inputData.networks.isEmpty else {
            return
        }

        // Create configuration
        let configuration = SwapAddMarketsTokenFlowConfigurationFactory.make(
            coinId: inputData.coinId,
            coinName: inputData.coinName,
            coinSymbol: inputData.coinSymbol,
            networks: inputData.networks,
            coordinator: self
        )

        // Present add token flow
        let viewModel = AccountsAwareAddTokenFlowViewModel(
            userWalletModels: userWalletRepository.models,
            configuration: configuration,
            coordinator: self
        )

        floatingSheetPresenter.enqueue(sheet: viewModel)
    }

    /// Called when a token is added via the add-token flow
    func onTokenAdded(item: AccountsAwareTokenSelectorItem) {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()

            // Add a small delay to avoid animation glitches
            try? await Task.sleep(for: .milliseconds(500))

            // Extract the view model from viewType and delegate selection
            if case .new(let swapViewModel) = viewType {
                swapViewModel.usedDidSelect(item: item)
            } else {
                AppLogger.error("onTokenAdded called with unexpected viewType: \(String(describing: viewType))", error: ExpressInteractorError.destinationNotFound)
            }
        }
    }
}

// MARK: - AccountsAwareAddTokenFlowRoutable

extension ActionButtonsSwapCoordinator: AccountsAwareAddTokenFlowRoutable {
    func close() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }

    func presentSuccessToast(with text: String) {
        Toast(view: SuccessToast(text: text))
            .present(
                layout: .top(padding: ToastConstants.topPadding),
                type: .temporary()
            )
    }

    func presentErrorToast(with text: String) {
        Toast(view: WarningToast(text: text))
            .present(
                layout: .top(padding: ToastConstants.topPadding),
                type: .temporary()
            )
    }
}

// MARK: - Factory methods

private extension ActionButtonsSwapCoordinator {
    func makeTokenSelectorViewModel() -> ActionButtonsTokenSelectorViewModel {
        TokenSelectorViewModel(
            tokenSelectorItemBuilder: ActionButtonsTokenSelectorItemBuilder(),
            strings: SwapTokenSelectorStrings(),
            expressTokensListAdapter: expressTokensListAdapter,
            tokenSorter: tokenSorter
        )
    }
}

extension ActionButtonsSwapCoordinator {
    enum ViewType: Identifiable {
        case legacy(ActionButtonsSwapViewModel)
        case new(AccountsAwareActionButtonsSwapViewModel)
        case express(ExpressCoordinator)

        var id: String {
            switch self {
            case .legacy: "legacy"
            case .new: "new"
            case .express: "express"
            }
        }
    }
}

// MARK: - Constants

private extension ActionButtonsSwapCoordinator {
    enum ToastConstants {
        static let topPadding: CGFloat = 52
    }
}
