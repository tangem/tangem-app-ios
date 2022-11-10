//
//  ExchangeFacadeFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

class ExchangeFacadeFactory {
    enum Router {
        case oneInch
    }

    func createFacade(for router: Router, exchangeManager: ExchangeManager, signer: TangemSigner, blockchainNetwork: BlockchainNetwork) -> ExchangeFacade {
        switch router {
        case .oneInch:
            return ExchangeOneInchFacade(exchangeManager: exchangeManager, signer: signer, blockchainNetwork: blockchainNetwork)
        }
    }
}
