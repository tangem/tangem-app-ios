//
//  PolymarketDeviceIdProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

protocol PolymarketDeviceIdProviding {
    func deviceId() throws -> String
}

struct KeychainPolymarketDeviceIdProvider {
    private let secureStorage: any PolymarketSecureStorage

    init(secureStorage: any PolymarketSecureStorage = SecureStorage()) {
        self.secureStorage = secureStorage
    }
}

// MARK: - PolymarketDeviceIdProviding protocol conformance

extension KeychainPolymarketDeviceIdProvider: PolymarketDeviceIdProviding {
    func deviceId() throws -> String {
        if let stored = try secureStorage.get(Constants.account), let deviceId = String(data: stored, encoding: .utf8) {
            return deviceId
        }

        let deviceId = UUID().uuidString.lowercased()
        try secureStorage.store(Data(deviceId.utf8), forKey: Constants.account, overwrite: true)

        return deviceId
    }
}

// MARK: - Constants

private extension KeychainPolymarketDeviceIdProvider {
    enum Constants {
        static let account = "polymarket_session_key_device_id"
    }
}
