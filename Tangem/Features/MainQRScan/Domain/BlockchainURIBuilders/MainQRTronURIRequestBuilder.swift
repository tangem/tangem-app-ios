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
        let amount = resolveTronAmount(parsedAmount: parsedAmount, rawAmountString: rawAmountString)

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
            rawTokenAmount: nil,
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

    /// The shared `QRCodeParser` already consumes `amount` / `value` / `uint256` (the same keys as
    /// `rawAmountQueryKeys`), so `parsedAmount` is only `nil` when its stricter decimal parsing failed
    /// (e.g. a comma decimal separator) — fall back to the lenient parser for that case only.
    private func resolveTronAmount(parsedAmount: Decimal?, rawAmountString: String?) -> Decimal? {
        if let parsedAmount {
            return parsedAmount
        }

        return rawAmountString.flatMap(MainQRDecimalParser.parseDecimal)
    }
}
