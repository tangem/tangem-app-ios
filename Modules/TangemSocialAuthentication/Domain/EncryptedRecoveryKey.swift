//
//  EncryptedRecoveryKey.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public struct EncryptedRecoveryKey: Equatable, Sendable {
    public let ciphertext: String
    public let keyId: String?

    public init(ciphertext: String, keyId: String?) {
        self.ciphertext = ciphertext
        self.keyId = keyId
    }
}
