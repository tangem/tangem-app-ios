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
        inputModel.explorerURL != nil
    }

    // MARK: - Dependencies

    private let inputModel: SwappingSuccessInputModel
    private unowned let coordinator: SwappingSuccessRoutable

    init(
        inputModel: SwappingSuccessInputModel,
        coordinator: SwappingSuccessRoutable
    ) {
        self.inputModel = inputModel
        self.coordinator = coordinator
    }

    func didTapViewInExplorer() {
        coordinator.openExplorer(
            url: inputModel.explorerURL,
            currencyName: inputModel.sourceCurrencyAmount.currency.name
        )
    }

    func didTapClose() {
        coordinator.didTapCloseButton()
    }
}
