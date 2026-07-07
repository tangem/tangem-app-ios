//
//  CardanoTransaction.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import PotentCBOR

struct CardanoTransaction {
    let body: CardanoTransactionBody
    let witnessSet: Data?
    let isValid: Bool
    let auxiliaryData: Data?
}
