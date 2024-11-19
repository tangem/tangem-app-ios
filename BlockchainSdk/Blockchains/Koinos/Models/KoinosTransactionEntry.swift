//
//  KoinosTransactionEntry.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct KoinosTransactionEntry {
    let id: String
    let sequenceNum: UInt64
    let payerAddress: String
    let rcLimit: UInt64
    let rcUsed: UInt64
    let event: KoinosTransferEvent
}
