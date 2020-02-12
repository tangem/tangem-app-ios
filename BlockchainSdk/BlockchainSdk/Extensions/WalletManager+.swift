//
//  Any+.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

extension WalletManager {
    public func then(_ block: (Self) -> Void) -> Self {
        block(self)
        return self
    }
}
