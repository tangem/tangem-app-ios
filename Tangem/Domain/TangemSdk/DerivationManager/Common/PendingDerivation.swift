//
//  PendingDerivation.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import struct TangemSdk.DerivationPath

struct PendingDerivation {
    let network: BlockchainNetwork
    let masterKey: KeyInfo
    let paths: [DerivationPath]
}
