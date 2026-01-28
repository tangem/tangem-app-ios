//
//  ExpressCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemExpress
import TangemFoundation
import TangemAccounts
import TangemLocalization
import class UIKit.UIApplication

final class ExpressCoordinator: CoordinatorObject {
    @Injected(\.safariManager) private var safariManager: SafariManager
    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: any FloatingSheetPresenter
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    let dismissAction: DismissAction
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root view model

    @Published private(set) var rootViewModel: ExpressViewModel?

    // MARK: - Child coordinators

    @Published var swappingSuccessCoordinator: SwappingSuccessCoordinator?

    // MARK: - Child view models

    @Published var expressTokensListViewModel: ExpressTokensListViewModel?
    @Published var swapTokenSelectorViewModel: SwapTokenSelectorViewModel?
    @Published var expressProvidersSelectorViewModel: ExpressProvidersSelectorViewModel?
    @Published var expressApproveViewModel: ExpressApproveViewModel?

    // MARK: - Express add token flow state

    private var expressAddTokenCompletion: ((TokenItem, any CryptoAccountModel) -> Void)?

    // MARK: - Properties

    private let factory: ExpressModulesFactory

    required init(
        factory: ExpressModulesFactory,
        dismissAction: @escaping DismissAction,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.factory = factory
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        rootViewModel = factory.makeExpressViewModel(coordinator: self)
    }
}

// MARK: - Options

extension ExpressCoordinator {
    enum Options {
        case `default`
    }

    typealias DismissAction = Action<DismissOptions?>
    typealias DismissOptions = FeeCurrencyNavigatingDismissOption
}

// MARK: - ExpressRoutable

extension ExpressCoordinator: ExpressRoutable {
    func presentSwappingTokenList(swapDirection: ExpressTokensListViewModel.SwapDirection) {
        expressTokensListViewModel = factory.makeExpressTokensListViewModel(swapDirection: swapDirection, coordinator: self)
    }

    func presentSwapTokenSelector(swapDirection: SwapTokenSelectorViewModel.SwapDirection) {
        swapTokenSelectorViewModel = factory.makeSwapTokenSelectorViewModel(swapDirection: swapDirection, coordinator: self)
    }

    func presentFeeSelectorView() {
        guard let feeSelectorViewModel = factory.makeFeeSelectorViewModel(coordinator: self) else {
            return
        }

        Task { @MainActor in floatingSheetPresenter.enqueue(sheet: feeSelectorViewModel) }
    }

    func presentApproveView(source: any ExpressInteractorSourceWallet, provider: ExpressProvider, selectedPolicy: BSDKApprovePolicy) {
        expressApproveViewModel = factory.makeExpressApproveViewModel(
            source: source,
            providerName: provider.name,
            selectedPolicy: selectedPolicy,
            coordinator: self
        )
    }

    func presentSuccessView(data: SentExpressTransactionData) {
        UIApplication.shared.endEditing()

        let dismissAction = { [weak self] in
            self?.swappingSuccessCoordinator = nil
            DispatchQueue.main.async {
                self?.dismiss(with: nil)
            }
        }

        let coordinator = SwappingSuccessCoordinator(
            dismissAction: dismissAction,
            popToRootAction: popToRootAction
        )
        coordinator.start(with: .express(factory: factory, data))

        swappingSuccessCoordinator = coordinator
    }

    func presentProviderSelectorView() {
        expressProvidersSelectorViewModel = factory.makeExpressProvidersSelectorViewModel(coordinator: self)
    }

    func presentFeeCurrency(feeCurrency: FeeCurrencyNavigatingDismissOption) {
        dismiss(with: feeCurrency)
    }

    func closeSwappingView() {
        dismiss(with: .none)
    }
}

// MARK: - FeeSelectorRoutable

extension ExpressCoordinator: SendFeeSelectorRoutable {
    func closeFeeSelector() {
        Task { @MainActor in floatingSheetPresenter.removeActiveSheet() }
    }

    func openFeeSelectorLearnMoreURL(_ url: URL) {
        Task { @MainActor in
            floatingSheetPresenter.pauseSheetsDisplaying()
            _ = safariManager.openURL(
                url,
                configuration: .init(),
                onDismiss: { [weak self] in self?.floatingSheetPresenter.resumeSheetsDisplaying() },
                onSuccess: { [weak self] _ in self?.floatingSheetPresenter.resumeSheetsDisplaying() },
            )
        }
    }
}

// MARK: - ExpressTokensListRoutable

extension ExpressCoordinator: ExpressTokensListRoutable {
    func closeExpressTokensList() {
        expressTokensListViewModel = nil
    }
}

// MARK: - SwapTokenSelectorRoutable

extension ExpressCoordinator: SwapTokenSelectorRoutable {
    func closeSwapTokenSelector() {
        swapTokenSelectorViewModel = nil
    }

    @MainActor
    func openAddTokenFlowForExpress(
        coinId: String,
        coinName: String,
        coinSymbol: String,
        swapDirection: SwapTokenSelectorViewModel.SwapDirection,
        userWalletInfo: UserWalletInfo,
        completion: @escaping (TokenItem, any CryptoAccountModel) -> Void
    ) {
        // Dismiss keyboard but keep token selector open
        UIApplication.shared.endEditing()

        // Store the completion for later
        expressAddTokenCompletion = completion

        // Load networks for this coin and then show the add-token flow
        Task { @MainActor in
            do {
                let networks = try await loadNetworks(for: coinId)

                guard !networks.isEmpty else {
                    // No networks available for this coin
                    return
                }

                showAddTokenFlow(
                    coinId: coinId,
                    coinName: coinName,
                    coinSymbol: coinSymbol,
                    networks: networks
                )
            } catch {
                // Failed to load networks
                AppLogger.error("Failed to load networks for coinId: \(coinId)", error: error)
            }
        }
    }

    private func loadNetworks(for coinId: String) async throws -> [NetworkModel] {
        let request = CoinsList.Request(
            supportedBlockchains: [],
            ids: [coinId]
        )

        let response = try await tangemApiService.loadCoins(requestModel: request)
        return response.coins.first?.networks ?? []
    }

    @MainActor
    private func showAddTokenFlow(
        coinId: String,
        coinName: String,
        coinSymbol: String,
        networks: [NetworkModel]
    ) {
        // Create configuration
        let configuration = ExpressAddTokenFlowConfigurationFactory.make(
            coinId: coinId,
            coinName: coinName,
            coinSymbol: coinSymbol,
            networks: networks,
            onTokenAdded: { [weak self] tokenItem, account in
                guard let self else { return }

                // Dismiss floating sheet first
                floatingSheetPresenter.removeActiveSheet()

                // Delay closing the token selector to allow floating sheet dismiss animation to complete
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(300))

                    // Call completion which will close the token selector
                    self.expressAddTokenCompletion?(tokenItem, account)
                    self.expressAddTokenCompletion = nil
                }
            }
        )

        // Get user wallet models
        let userWalletModels = userWalletRepository.models

        // Present add token flow
        let viewModel = AccountsAwareAddTokenFlowViewModel(
            userWalletModels: userWalletModels,
            configuration: configuration,
            coordinator: self
        )

        floatingSheetPresenter.enqueue(sheet: viewModel)
    }
}

func presentSuccessToast(with text: String) {
    // Intentionally left empty: the Express flow communicates success via
    // sheet dismissal and updated token lists instead of a separate toast.
}

extension ExpressCoordinator: AccountsAwareAddTokenFlowRoutable {
    func close() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }

    func presentSuccessToast(with text: String) {}

    func presentErrorToast(with text: String) {}
}

// MARK: - ExpressApproveRoutable

extension ExpressCoordinator: ExpressApproveRoutable {
    func didSendApproveTransaction() {
        expressApproveViewModel = nil
        rootViewModel?.didCloseApproveSheet()
    }

    func userDidCancel() {
        expressApproveViewModel = nil
        rootViewModel?.didCloseApproveSheet()
    }

    func openLearnMore() {
        safariManager.openURL(TangemBlogUrlBuilder().url(post: .giveRevokePermission))
    }
}

// MARK: - ExpressProvidersSelectorRoutable

extension ExpressCoordinator: ExpressProvidersSelectorRoutable {
    func closeExpressProvidersSelector() {
        expressProvidersSelectorViewModel = nil
    }
}
