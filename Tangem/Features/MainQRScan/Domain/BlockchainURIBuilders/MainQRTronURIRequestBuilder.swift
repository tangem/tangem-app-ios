//
//  MainQRTronURIRequestBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct MainQRTronURIRequestBuilder: MainQRBlockchainURIRequestBuilder {
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

        let tokenValue = MainQRParserSupport.firstQueryValue(
            in: queryItems,
            names: [MainQRParserConstants.QueryKey.token]
        )
        let explicitSymbol = MainQRParserSupport.firstQueryValue(
            in: queryItems,
            names: [MainQRParserConstants.QueryKey.symbol, MainQRParserConstants.QueryKey.ticker]
        )

        let rawAmountString = MainQRParserSupport.firstQueryValue(
            in: queryItems,
            names: MainQRParserConstants.rawAmountQueryKeys
        )
        let (amount, rawTokenAmount) = resolveTronAmount(
            parsedAmount: parsedAmount,
            rawAmountString: rawAmountString
        )

        let unknown = MainQRParserSupport.unknownParameters(
            in: queryItems,
            knownKeys: knownKeys(supportsMemo: blockchainSupportsMemo)
        )

        return MainQRPaymentRequest(
            blockchain: blockchain,
            destinationAddress: destination,
            amount: amount,
            memo: memo,
            tokenSymbol: explicitSymbol ?? tokenValue,
            tokenContractAddress: tokenValue,
            rawTokenAmount: rawTokenAmount,
            unknownParameters: unknown
        )
    }

    // MARK: - Private

    private func knownKeys(supportsMemo: Bool) -> Set<String> {
        var keys = Set<String>()
        MainQRParserConstants.rawAmountQueryKeys.forEach { keys.insert($0) }
        MainQRParserConstants.tronTokenSymbolQueryKeys.forEach { keys.insert($0) }
        if supportsMemo {
            MainQRParserConstants.memoQueryKeys.forEach { keys.insert($0) }
        }
        return keys
    }

    private func resolveTronAmount(
        parsedAmount: Decimal?,
        rawAmountString: String?
    ) -> (amount: Decimal?, rawTokenAmount: Decimal?) {
        if let parsedAmount {
            return (parsedAmount, nil)
        }

        guard let rawAmountString, let parsed = MainQRDecimalParser.parseDecimal(rawAmountString) else {
            return (nil, nil)
        }

        let hasDecimalPoint = rawAmountString.contains(".") || rawAmountString.contains(",")

        if hasDecimalPoint {
            return (parsed, nil)
        }

        if parsed <= MainQRParserConstants.tronRawAmountThreshold {
            return (parsed, nil)
        }

        MainQRScanLogger.warning(MainQRScanLoggerStrings.tronAmountTreatedAsRaw(rawValue: rawAmountString))
        return (nil, parsed)
    }
}
