//
//  UserWalletId.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import CryptoKit

public struct UserWalletId: Hashable, Sendable {
    public let value: Data
    public let stringValue: String

    public init(value: Data) {
        self.value = value
        stringValue = value.hexString
    }
}

public extension UserWalletId {
    init(with walletPublicKey: Data) {
        let keyHash = Data(SHA256.hash(data: walletPublicKey))
        let key = SymmetricKey(data: keyHash)
        let authenticationCode = HMAC<SHA256>.authenticationCode(for: Constants.message, using: key)
        value = Data(authenticationCode)
        stringValue = value.hexString
    }
}

public extension UserWalletId {
    /// ``value`` hashed using SHA256 algorithm and converted to a hex-formatted string.
    var hashedStringValue: String {
        keyHash.hexString
    }

    /// ``value`` and `message` hashed using HMAC-SHA256 algorithm and converted to a hex-formatted string.
    func hashedStringValue(message: String) -> String {
        let key = SymmetricKey(data: keyHash)
        let authenticationCode = HMAC<SHA256>.authenticationCode(for: Data(message.utf8), using: key)
        return Data(authenticationCode).hexString
    }

    private var keyHash: Data {
        Data(SHA256.hash(data: value))
    }
}

private extension Data {
    var hexString: String {
        return map { return String(format: "%02X", $0) }.joined()
    }
}

private extension UserWalletId {
    enum Constants {
        static let message = "UserWalletID".data(using: .utf8)!
    }
}
