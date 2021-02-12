//
//  TokensServiceFactory.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

class TokensServiceFactory {
    static func service(for card: Card, tokensService: TokensPersistenceService) -> TokensService {
        guard let blockchain = card.blockchain else { return DefaultTokensService() }
        switch blockchain {
        case .ethereum:
            return EthereumTokensService.instance(tokenService: tokensService)
        default:
            return DefaultTokensService()
        }
    }
}
