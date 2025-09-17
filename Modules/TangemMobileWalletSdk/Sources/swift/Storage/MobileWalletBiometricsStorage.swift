//
//  MobileWalletBiometricsStorage.swift
//  TangemMobileWalletSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import LocalAuthentication
import TangemSdk

public protocol MobileWalletBiometricsStorage {
    func get(_ account: String, context: LAContext?) throws -> Data?
    func store(_ object: Data, forKey account: String, overwrite: Bool) throws
    func delete(_ account: String) throws
    func hasValue(account: String) -> Bool
}

extension MobileWalletBiometricsStorage {
    func store(_ object: Data, forKey account: String) throws {
        try store(object, forKey: account, overwrite: true)
    }
}

extension BiometricsStorage: MobileWalletBiometricsStorage {
    public func hasValue(account: String) -> Bool {
        SecureEnclaveHelper.hasValue(account: account)
    }
}
