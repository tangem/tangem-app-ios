//
//  RIPEMD160+.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

extension RIPEMD160 {
    static func hash(_ message: Data) -> Data {
        var md = RIPEMD160()
        md.update(data: message)
        return md.finalize()
    }
}
