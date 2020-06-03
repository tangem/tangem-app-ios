//
//  CCCCryptorStatus+Error.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import CommonCrypto

extension CCCryptorStatus: Error, LocalizedError {
    public var errorDescription: String? {
        return "CCCryptor error. Code: \(self)"
    }
}
