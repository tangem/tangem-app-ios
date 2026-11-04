//
//  PolymarketDeviceIdProviderTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("Polymarket device id")
struct PolymarketDeviceIdProviderTests {
    @Test("The first read mints the device id and every later read returns the same one")
    func deviceIdIsMintedOnce() throws {
        let storage = PolymarketSecureStorageSpy()

        let firstRead = try KeychainPolymarketDeviceIdProvider(secureStorage: storage).deviceId()
        let laterRead = try KeychainPolymarketDeviceIdProvider(secureStorage: storage).deviceId()

        #expect(laterRead == firstRead)
    }

    @Test("A Keychain that cannot be read fails instead of minting another device id")
    func unreadableKeychainKeepsTheDeviceId() {
        let storage = PolymarketSecureStorageSpy(items: [Constants.account: Data(Constants.deviceId.utf8)])
        storage.readError = TestError.storage

        #expect(throws: TestError.storage) {
            try KeychainPolymarketDeviceIdProvider(secureStorage: storage).deviceId()
        }
        #expect(storage.items[Constants.account] == Data(Constants.deviceId.utf8))
    }
}

// MARK: - Helpers

private extension PolymarketDeviceIdProviderTests {
    enum Constants {
        static let account = "polymarket_session_key_device_id"
        static let deviceId = "3f2a7c1e-5b6d-4e8f-9a0b-1c2d3e4f5a6b"
    }
}

// MARK: - Stubs

private enum TestError: Error {
    case storage
}
