//
//  MainQRDefaultURIRequestBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct MainQRDefaultURIRequestBuilder: MainQRBlockchainURIRequestBuilder {
    func buildRequest(
        blockchain: Blockchain,
        destination: String,
        parsedAmount: Decimal?,
        parsedMemo: String?,
        queryItems: [URLQueryItem]
    ) -> MainQRPaymentRequest {
        let blockchainSupportsMemo = blockchain.hasMemo || blockchain.hasDestinationTag

        let memo: String?
        if blockchainSupportsMemo {
            memo = parsedMemo ?? MainQRParserSupport.firstQueryValue(
                in: queryItems,
                names: MainQRParserConstants.memoQueryKeys
            )
        } else {
            memo = parsedMemo
        }

        let tokenSymbol = MainQRParserSupport.firstQueryValue(
            in: queryItems,
            names: MainQRParserConstants.tokenSymbolQueryKeys
        )
        let tokenContractAddress = MainQRParserSupport.firstQueryValue(
            in: queryItems,
            names: MainQRParserConstants.tokenContractQueryKeys
        )

        let unknown = MainQRParserSupport.unknownParameters(
            in: queryItems,
            knownKeys: knownKeys(supportsMemo: blockchainSupportsMemo)
        )

        return MainQRPaymentRequest(
            blockchain: blockchain,
            destinationAddress: destination,
            amount: parsedAmount,
            memo: memo,
            tokenSymbol: tokenSymbol,
            tokenContractAddress: tokenContractAddress,
            rawTokenAmount: nil,
            unknownParameters: unknown
        )
    }

    // MARK: - Private

    private func knownKeys(supportsMemo: Bool) -> Set<String> {
        var keys = Set<String>()
        MainQRParserConstants.rawAmountQueryKeys.forEach { keys.insert($0) }
        MainQRParserConstants.tokenSymbolQueryKeys.forEach { keys.insert($0) }
        MainQRParserConstants.tokenContractQueryKeys.forEach { keys.insert($0) }
        if supportsMemo {
            MainQRParserConstants.memoQueryKeys.forEach { keys.insert($0) }
        }
        return keys
    }
}
