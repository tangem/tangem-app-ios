//
//  File.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TrezorCrypto
import TangemSdk

enum CardanoUtil {
    static var stakingDerivationPath: DerivationPath {
        try! DerivationPath(rawPath: stakingDerivationPathString)
    }

    static let defaultDerivationPathString = "m/1852'/1815'/0'/0/0"
    static let stakingDerivationPathString = "m/1852'/1815'/0'/2/0"
}
