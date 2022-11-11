//
//  ExchangeViewModelFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

class ExchangeViewModelFactory {
    func createExchangeViewModel(exchangeManager: ExchangeManager,
                                 amountType: Amount.AmountType,
                                 signer: TangemSigner,
                                 blockchainNetwork: BlockchainNetwork,
                                 exchangeRouter: ExchangeFacadeFactory.Router) -> ExchangeViewModel {

        let exchangeFacadeFactory = ExchangeFacadeFactory()
        let tokensFactory = ExchangeTokensFactory()

        let exchangeCurrency: ExchangeCurrency
        switch amountType {
        case .coin, .reserve:
            exchangeCurrency = tokensFactory.createCoin(for: blockchainNetwork)
        case .token:
            let contractAddress = amountType.token!.contractAddress
            exchangeCurrency = ExchangeCurrency(type: .token(blockchainNetwork, contractAddress: contractAddress),
                                                name: amountType.token!.name,
                                                symbol: amountType.token!.symbol,
                                                decimalCount: Decimal(amountType.token!.decimalCount))
        }

        let destinationCurrency: ExchangeCurrency
        switch exchangeCurrency.type {
        case .coin:
            destinationCurrency = ExchangeCurrency.daiToken(blockchainNetwork: blockchainNetwork)
        case .token:
            destinationCurrency = ExchangeCurrency(type: .coin(blockchainNetwork))
        }

        let exchangeFacade = exchangeFacadeFactory.createFacade(for: exchangeRouter,
                                                                exchangeManager: exchangeManager,
                                                                signer: signer,
                                                                blockchainNetwork: blockchainNetwork)

        return ExchangeViewModel(exchangeFacade: exchangeFacade,
                                 sourceCurrency: exchangeCurrency,
                                 destinationCurrency: destinationCurrency)
    }
}
