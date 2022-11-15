//
//  ExchangeProviderFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

class ExchangeProviderFactory {
    enum Router {
        case oneInch
    }

    func createFacade(for router: Router, exchangeManager: ExchangeManager, signer: TangemSigner, blockchainNetwork: BlockchainNetwork) -> ExchangeProvider {
        switch router {
        case .oneInch:
            return ExchangeOneInchProvider(exchangeManager: exchangeManager, signer: signer, blockchainNetwork: blockchainNetwork)
        }
    }
}
