//
//  SentExpressTransactionData.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

struct SentSwapTransactionData {
    let result: TransactionDispatcherResult
    let source: any SendSourceToken
    let receive: any SendReceiveToken
    let fee: BSDKFee
    let provider: ExpressProvider
    let date: Date
    let expressTransactionData: ExpressTransactionData
}
