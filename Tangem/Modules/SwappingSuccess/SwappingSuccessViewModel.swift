//
//  SwappingSuccessViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine
import TangemExchange

final class SwappingSuccessViewModel: ObservableObject {
    // MARK: - ViewState

    var sourceFormatted: String {
        inputModel.sourceCurrencyAmount.formatted
    }

    var resultFormatted: String {
        inputModel.resultCurrencyAmount.formatted
    }

    var isViewInExplorerAvailable: Bool {
        explorerLink != nil
    }

    // MARK: - Dependencies

    private let inputModel: SwappingSuccessInputModel
    private let explorerLinkProvider: ExplorerLinkProviding
    private unowned let coordinator: SwappingSuccessRoutable

    private var explorerLink: URL? {
        explorerLinkProvider.getExplorerURL(
            for: inputModel.sourceCurrencyAmount.currency.blockchain,
            transaction: inputModel.transactionHash
        )
    }

    init(
        inputModel: SwappingSuccessInputModel,
        explorerLinkProvider: ExplorerLinkProviding,
        coordinator: SwappingSuccessRoutable
    ) {
        self.inputModel = inputModel
        self.explorerLinkProvider = explorerLinkProvider
        self.coordinator = coordinator
    }

    func didTapViewInExplorer() {
        guard let url = explorerLink else { return }

        coordinator.openExplorer(
            url: url,
            currencyName: inputModel.sourceCurrencyAmount.currency.name
        )
    }

    func didTapClose() {
        coordinator.didTapCloseButton()
    }
}
