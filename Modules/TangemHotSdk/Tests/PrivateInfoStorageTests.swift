//
//  PrivateInfoStorageTests.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import LocalAuthentication
@testable import TangemHotSdk

struct PrivateInfoStorageTests {
    private func makePrivateInfo() -> PrivateInfo {
        let entropy = Data([0x01, 0x02, 0x03, 0x04, 0x05])

        let passphrase = "test-passphrase"
        return PrivateInfo(entropy: entropy, passphrase: passphrase)
    }

    private func makeStorage() -> PrivateInfoStorage {
        PrivateInfoStorage(
            secureStorage: MockedSecureStorage(),
            biometricsStorage: MockedBiometricsStorage(),
            accessCodeSecureEnclaveService: MockedSecureEnclaveService(config: .default),
            biometricsSecureEnclaveServiceType: MockedSecureEnclaveService.self,
        )
    }

    @Test
    func testCreateUnsecured() throws {
        let storage = makeStorage()
        let walletID = HotWalletID()

        let encoded = makePrivateInfo().encode()

        try storage.storeUnsecured(privateInfoData: encoded, walletID: walletID)

        let result = try storage.getPrivateInfoData(for: walletID, auth: nil)

        #expect(result == encoded, "Stored data should match the original encoded data")
    }

    @Test
    func testUpdateAccessCodeSuccess() throws {
        let storage = makeStorage()
        let walletID = HotWalletID()

        let encoded = makePrivateInfo().encode()

        try storage.storeUnsecured(privateInfoData: encoded, walletID: walletID)
        try storage.updateAccessCode("accessCode", oldAuth: nil, for: walletID)

        try storage.updateAccessCode("newAccessCode", oldAuth: .accessCode("accessCode"), for: walletID)

        let result = try storage.getPrivateInfoData(for: walletID, auth: .accessCode("newAccessCode"))

        #expect(result == encoded, "Stored data should match the original encoded data")
    }

    @Test
    func testUpdateInvalidAccessCodeFail() throws {
        let storage = makeStorage()
        let walletID = HotWalletID()

        let encoded = makePrivateInfo().encode()

        try storage.storeUnsecured(privateInfoData: encoded, walletID: walletID)
        try storage.updateAccessCode("accessCode", oldAuth: nil, for: walletID)

        #expect(throws: Error.self, performing: {
            try storage.updateAccessCode("newAccessCode", oldAuth: .accessCode("invalidAccessCode"), for: walletID)
        })
    }

    @Test
    func testSetBiometricWithValidAccessCodeSuccess() throws {
        let storage = makeStorage()
        let walletID = HotWalletID()

        let encoded = makePrivateInfo().encode()

        try storage.storeUnsecured(privateInfoData: encoded, walletID: walletID)
        try storage.updateAccessCode("accessCode", oldAuth: nil, for: walletID)

        try storage.enableBiometrics(for: walletID, accessCode: "accessCode", context: LAContext())

        let result = try storage.getPrivateInfoData(for: walletID, auth: .biometrics(context: LAContext()))

        #expect(result == encoded, "Stored data should match the original encoded data")
    }

    @Test
    func testSetBiometricsWithInvalidAccessCodeFail() throws {
        let storage = makeStorage()
        let walletID = HotWalletID()

        let encoded = makePrivateInfo().encode()

        try storage.storeUnsecured(privateInfoData: encoded, walletID: walletID)
        try storage.updateAccessCode("accessCode", oldAuth: nil, for: walletID)

        #expect(throws: Error.self, performing: {
            try storage.enableBiometrics(for: walletID, accessCode: "invalidAccessCode", context: LAContext())
        })
    }

    @Test
    func testBiometricsUnlockMustUnlockNonSecuredWallet() throws {
        let storage = makeStorage()
        let walletID = HotWalletID()

        let encoded = makePrivateInfo().encode()

        try storage.storeUnsecured(privateInfoData: encoded, walletID: walletID)
        let result = try storage.getPrivateInfoData(for: walletID, auth: .biometrics(context: LAContext()))

        #expect(result == encoded, "Stored data should match the original encoded data")
    }

    @Test
    func testDeleteWalletSuccess() throws {
        let storage = makeStorage()
        let walletID = HotWalletID()

        let encoded = makePrivateInfo().encode()

        try storage.storeUnsecured(privateInfoData: encoded, walletID: walletID)
        try storage.delete(hotWalletID: walletID)

        #expect(throws: Error.self, performing: {
            try storage.getPrivateInfoData(for: walletID, auth: .biometrics(context: LAContext()))
        })
    }

    @Test
    func testDeleteWalletFailure() throws {
        let storage = makeStorage()
        let walletID = HotWalletID()

        #expect(throws: Error.self, performing: {
            try storage.delete(hotWalletID: walletID)
        })
    }
}
