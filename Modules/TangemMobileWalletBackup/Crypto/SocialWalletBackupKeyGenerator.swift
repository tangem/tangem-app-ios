//
//  SocialWalletBackupKeyGenerator.swift
//  TangemMobileWalletBackup
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Security
import TangemFoundation

public struct SocialWalletBackupKeyGenerator {
    public init() {}

    public func makeKey() throws(WalletBackupCryptoError) -> Data {
        var key = Data(count: AESGCMWalletBackupCryptor.keyLength)
        let status: OSStatus = key.withUnsafeMutableBytes { buffer in
            guard let baseAddress = buffer.baseAddress else {
                return errSecParam
            }
            return SecRandomCopyBytes(kSecRandomDefault, buffer.count, baseAddress)
        }

        guard status == errSecSuccess else {
            key.secureErase()
            throw WalletBackupCryptoError.randomGenerationFailed
        }

        return key
    }
}
