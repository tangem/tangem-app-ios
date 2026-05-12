//
//  UserWalletId.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import CryptoKit

public struct UserWalletId: Hashable {
    public let value: Data
    public let stringValue: String

    public init(value: Data) {
        let resolved = UserWalletIdSpoofer.shared.resolve(value) ?? value
        self.value = resolved
        stringValue = resolved.hexString
    }
}

public extension UserWalletId {
    init(with walletPublicKey: Data) {
        let keyHash = Data(SHA256.hash(data: walletPublicKey))
        let key = SymmetricKey(data: keyHash)
        let authenticationCode = HMAC<SHA256>.authenticationCode(for: Constants.message, using: key)
        self.init(value: Data(authenticationCode))
    }
}

private extension UserWalletId {
    enum Constants {
        static let message = "UserWalletID".data(using: .utf8)!
    }
}
