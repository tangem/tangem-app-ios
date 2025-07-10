//
//  ALPH+TxInputData.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

extension ALPH {
    struct TxInputInfo {
        let outputRef: AssetOutputRef
        let unlockScript: UnlockScript
    }
}
