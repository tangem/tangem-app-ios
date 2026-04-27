//
//  KoinosTransferEvent.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct KoinosTransferEvent {
    let fromAccount: String
    let toAccount: String
    let value: UInt64
}
