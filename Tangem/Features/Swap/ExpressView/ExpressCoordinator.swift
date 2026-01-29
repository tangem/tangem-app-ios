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
import TangemUI
import class UIKit.UIApplication

final class ExpressCoordinator: CoordinatorObject {
    @Injected(\.safariManager) private var safariManager: SafariManager
    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: any FloatingSheetPresenter
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

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

    func onTokenAdded(item: AccountsAwareTokenSelectorItem) {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()

            try? await Task.sleep(for: .milliseconds(500))

            // Delegate to swapTokenSelectorViewModel to handle the selection
            swapTokenSelectorViewModel?.usedDidSelect(item: item)
        }
    }
}

// MARK: - AccountsAwareAddTokenFlowRoutable

extension ExpressCoordinator: AccountsAwareAddTokenFlowRoutable {
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

// MARK: - Constants

private extension ExpressCoordinator {
    enum ToastConstants {
        static let topPadding: CGFloat = 52
    }
}
