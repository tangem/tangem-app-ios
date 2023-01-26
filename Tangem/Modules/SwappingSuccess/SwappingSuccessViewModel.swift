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
    private let userWalletModel: UserWalletModel
    private let currencyMapper: CurrencyMapping
    private let blockchainNetwork: BlockchainNetwork
    private unowned let coordinator: SwappingSuccessRoutable

    init(
        inputModel: SwappingSuccessInputModel,
        userWalletModel: UserWalletModel,
        currencyMapper: CurrencyMapping,
        blockchainNetwork: BlockchainNetwork,
        coordinator: SwappingSuccessRoutable
    ) {
        self.inputModel = inputModel
        self.userWalletModel = userWalletModel
        self.currencyMapper = currencyMapper
        self.blockchainNetwork = blockchainNetwork
        self.coordinator = coordinator
    }

    func didTapViewInExplorer() {
        coordinator.openExplorer(
            url: inputModel.explorerURL,
            currencyName: inputModel.sourceCurrencyAmount.currency.name
        )
    }

    func didTapClose() {
        let destination = inputModel.resultCurrencyAmount.currency
        if let token = currencyMapper.mapToToken(currency: destination) {
            let entry = StorageEntry(blockchainNetwork: blockchainNetwork, token: token)
            userWalletModel.append(entries: [entry])
            userWalletModel.updateWalletModels()
        }

        coordinator.didTapCloseButton()
    }
}
