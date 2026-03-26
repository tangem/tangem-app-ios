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
    /// Raw token amount in the smallest unit (e.g. uint256 from EIP-681).
    /// Requires conversion using token's `decimalCount` before use.
    let rawTokenAmount: Decimal?
    /// Query parameters that were present in the URI but not recognized by the parser.
    let unknownParameters: [String: String]

    init(
        blockchain: Blockchain,
        destinationAddress: String,
        amount: Decimal?,
        memo: String?,
        tokenSymbol: String?,
        tokenContractAddress: String?,
        rawTokenAmount: Decimal?,
        unknownParameters: [String: String] = [:]
    ) {
        self.blockchain = blockchain
        self.destinationAddress = destinationAddress
        self.amount = amount
        self.memo = memo
        self.tokenSymbol = tokenSymbol
        self.tokenContractAddress = tokenContractAddress
        self.rawTokenAmount = rawTokenAmount
        self.unknownParameters = unknownParameters
    }
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
    let qrType: String?

    init(
        symbol: String?,
        networkId: String?,
        qrType: String? = nil
    ) {
        let trimmedSymbol = symbol?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.symbol = (trimmedSymbol?.isEmpty == false) ? trimmedSymbol : nil

        let trimmedNetworkId = networkId?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.networkId = (trimmedNetworkId?.isEmpty == false) ? trimmedNetworkId : nil

        self.qrType = qrType
    }

    static func payment(_ request: MainQRPaymentRequest) -> MainQRNoSupportedTokensContext {
        return MainQRNoSupportedTokensContext(
            symbol: request.tokenSymbol,
            networkId: request.blockchain.networkId,
            qrType: Analytics.ParameterValue.paymentUri.rawValue
        )
    }
}
