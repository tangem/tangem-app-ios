//
//  RemoteCollectiblesBuybackTransactionGenerator+Mapper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension RemoteCollectiblesBuybackTransactionGenerator {
    enum Mapper {
        static func mapToTransaction(
            _ response: CollectiblesDTO.GenerateBuybackDataResponse
        ) throws -> CollectiblesBuybackTransaction {
            let txData = response.txData
            let amount = try CollectiblesAPIService.Mapper.mapToPayout(
                baseUnits: txData.toAmount,
                decimals: txData.toDecimals
            )

            guard let transaction = Data(base64Encoded: txData.tx) else {
                let context = DecodingError.Context(
                    codingPath: [],
                    debugDescription: "The buyback transaction is not base64"
                )
                throw CollectiblesAPIService.Error.decoding(.dataCorrupted(context))
            }

            return CollectiblesBuybackTransaction(
                buybackID: response.buybackID,
                memo: txData.memo,
                amount: amount,
                transaction: transaction
            )
        }
    }
}
