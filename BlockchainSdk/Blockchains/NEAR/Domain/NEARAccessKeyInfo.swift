//
//  NEARAccessKeyInfo.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct NEARAccessKeyInfo {
    let currentNonce: UInt
    let recentBlockHash: String
    let canBeUsedForTransfer: Bool
}
