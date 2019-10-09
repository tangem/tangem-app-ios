//
//  CryptoUtils.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

class CryptoUtils {
    static func generateRandomBytes(count: Int) -> Data? {
        var bytes = Data(repeating: 0, count: count)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        
        if status == errSecSuccess {
            return bytes
        } else {
            return nil
        }
    }
}
