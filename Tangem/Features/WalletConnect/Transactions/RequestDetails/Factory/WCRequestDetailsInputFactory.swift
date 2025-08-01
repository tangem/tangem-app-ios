//
//  WCRequestDetailsInputFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

protocol WCRequestDetailsInputFactory {
    func createRequestDetailsInput(
        transactionData: WCHandleTransactionData,
        simulationResult: BlockaidChainScanResult?,
        backAction: @escaping () -> Void
    ) -> WCRequestDetailsInput
}

final class CommonWCRequestDetailsInputFactory: WCRequestDetailsInputFactory {
    func createRequestDetailsInput(
        transactionData: WCHandleTransactionData,
        simulationResult: BlockaidChainScanResult?,
        backAction: @escaping () -> Void
    ) -> WCRequestDetailsInput {
        let builder = WCRequestDetailsBuilder(
            method: transactionData.method,
            source: transactionData.requestData,
            blockchain: transactionData.blockchain,
            simulationResult: simulationResult
        )

        return WCRequestDetailsInput(
            builder: builder,
            rawTransaction: transactionData.rawTransaction,
            simulationResult: simulationResult,
            backAction: backAction
        )
    }
}
