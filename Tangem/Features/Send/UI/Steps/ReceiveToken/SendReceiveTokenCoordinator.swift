//
//  SendReceiveTokenCoordinator.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class SendReceiveTokenCoordinator: CoordinatorObject {
    /// Non-nil payload requests opening the regular Swap flow after the Send flow is dismissed.
    let dismissAction: Action<SwapNavigatingDismissOption?>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Dependencies

    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: any FloatingSheetPresenter

    // MARK: - Root view model

    @Published private(set) var rootViewModel: SendReceiveTokensListViewModel?

    // MARK: - Child view models

    @Published var receiveTokenNetworkSelectorViewModel: SendReceiveTokenNetworkSelectorViewModel?

    // MARK: - Dependencies

    private let receiveTokensListBuilder: SendReceiveTokensListBuilder
    private var marketsTokenAdditionCoordinator: SwapMarketsTokenAdditionCoordinator?

    required init(
        receiveTokensListBuilder: SendReceiveTokensListBuilder,
        dismissAction: @escaping Action<SwapNavigatingDismissOption?>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.receiveTokensListBuilder = receiveTokensListBuilder
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        rootViewModel = receiveTokensListBuilder.makeReceiveTokensListViewModel(router: self)
    }
}

// MARK: - Options

extension SendReceiveTokenCoordinator {
    enum Options {
        case `default`
    }
}

// MARK: - SendReceiveTokensListViewRoutable

extension SendReceiveTokenCoordinator: SendReceiveTokensListViewRoutable {
    func openNetworkSelector(coin: CoinModel, networks: [TokenItem]) {
        let selectorViewModel = receiveTokensListBuilder
            .makeReceiveTokenNetworkSelectorViewModel(coin: coin, networks: networks, router: self)

        Task { @MainActor in
            floatingSheetPresenter.enqueue(sheet: selectorViewModel)
        }
    }

    func closeTokensList() {
        dismiss(with: nil)
    }
}

// MARK: - SendReceiveTokenNetworkSelectorViewRoutable

extension SendReceiveTokenCoordinator: SendReceiveTokenNetworkSelectorViewRoutable {
    func dismissNetworkSelector(isSelected: Bool) {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()

            if isSelected {
                dismiss(with: nil)
            }
        }
    }

    func openManualSwap(option: SwapNavigatingDismissOption) {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
            dismiss(with: option)
        }
    }

    func openAddTokenFlow(
        inputData: ExpressAddTokenInputData,
        makeSwapOption: @escaping (TokenItem) -> SwapNavigatingDismissOption
    ) {
        let additionCoordinator = SwapMarketsTokenAdditionCoordinator(onTokenAdded: { [weak self] item in
            self?.marketsTokenAdditionCoordinator = nil
            self?.openManualSwap(option: makeSwapOption(item.tokenItem))
        })

        marketsTokenAdditionCoordinator = additionCoordinator

        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
            additionCoordinator.requestAddToken(inputData: inputData)
        }
    }
}
