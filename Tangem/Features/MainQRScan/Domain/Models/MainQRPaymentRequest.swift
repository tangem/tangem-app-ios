//
//  MainQRPaymentRequest.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct MainQRPaymentRequest: Equatable {
    let blockchain: Blockchain
    let destinationAddress: String
    let amount: Decimal?
    let memo: String?
    let tokenSymbol: String?
    let tokenContractAddress: String?
}

struct MainQRResolvedPaymentRequest: Equatable {
    let request: MainQRPaymentRequest
    let matchingTokenItems: [TokenItem]
}

struct MainQRAddressRequest: Equatable {
    let destinationAddress: String
    let matchingBlockchains: [Blockchain]
}

struct MainQRNoSupportedTokensContext: Equatable {
    let symbol: String?
    let networkId: String?

    init(
        symbol: String?,
        networkId: String?
    ) {
        let trimmedSymbol = symbol?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.symbol = (trimmedSymbol?.isEmpty == false) ? trimmedSymbol : nil

        let trimmedNetworkId = networkId?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.networkId = (trimmedNetworkId?.isEmpty == false) ? trimmedNetworkId : nil
    }

    static func payment(_ request: MainQRPaymentRequest) -> MainQRNoSupportedTokensContext {
        return MainQRNoSupportedTokensContext(
            symbol: request.tokenSymbol,
            networkId: request.blockchain.networkId
        )
    }
}
