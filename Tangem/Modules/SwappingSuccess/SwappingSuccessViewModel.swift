//
//  SwappingSuccessViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine
import TangemSwapping
import Foundation

final class SwappingSuccessViewModel: ObservableObject {
    // MARK: - ViewState

    var sourceFormatted: String {
        inputModel.sourceCurrencyAmount.formatted
    }

    var resultFormatted: String {
        inputModel.resultCurrencyAmount.formatted
    }

    var isViewInExplorerAvailable: Bool {
        explorerURL != nil
    }

    // MARK: - Dependencies

    private let inputModel: SwappingSuccessInputModel
    private let explorerURLService: ExplorerURLService
    private unowned let coordinator: SwappingSuccessRoutable

    private var explorerURL: URL? {
        explorerURLService.getExplorerURL(
            for: inputModel.sourceCurrencyAmount.currency.blockchain,
            transactionID: inputModel.transactionID
        )
    }

    init(
        inputModel: SwappingSuccessInputModel,
        explorerURLService: ExplorerURLService,
        coordinator: SwappingSuccessRoutable
    ) {
        self.inputModel = inputModel
        self.explorerURLService = explorerURLService
        self.coordinator = coordinator
    }

    func didTapViewInExplorer() {
        guard let url = explorerURL else { return }

        coordinator.openExplorer(
            url: url,
            currencyName: inputModel.sourceCurrencyAmount.currency.name
        )
    }

    func didTapClose() {
        coordinator.didTapCloseButton()
    }
}
