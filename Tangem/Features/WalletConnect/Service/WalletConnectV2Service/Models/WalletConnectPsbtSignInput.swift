//
//  WalletConnectPsbtSignInput.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct WalletConnectPsbtSignInput: Codable {
    let address: String
    let index: Int
    let sighashTypes: [Int]?
}
