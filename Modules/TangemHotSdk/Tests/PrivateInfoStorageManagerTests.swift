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
@testable import TangemFoundation

struct PrivateInfoStorageManagerTests {
    private let walletID = UserWalletId(value: Data(hexString: "test"))

    private func makePrivateInfo() -> PrivateInfo {
        let passphrase = "test-passphrase"
        return PrivateInfo(entropy: entropy, passphrase: passphrase)
    }

    private func makeStorage() -> PrivateInfoStorageManager {
        let mockedSecureStorage = MockedSecureStorage()
        let mockedSecureEnclaveService = MockedSecureEnclaveService(config: .default)
        let mockedBiometricsStorage = MockedBiometricsStorage()

        return PrivateInfoStorageManager(
            privateInfoStorage: PrivateInfoStorage(
                secureStorage: mockedSecureStorage,
                secureEnclaveService: mockedSecureEnclaveService
            ),
            encryptionKeySecureStorage: EncryptionKeySecureStorage(
                secureStorage: mockedSecureStorage,
                secureEnclaveService: mockedSecureEnclaveService
            ),
            encryptionKeyBiometricsStorage: EncryptionKeyBiometricsStorage(biometricsStorage: mockedBiometricsStorage, secureEnclaveServiceType: MockedSecureEnclaveService.self)
        )
    }

    @Test
    func testCreateUnsecured() throws {
        let storage = makeStorage()

        let encoded = makePrivateInfo().encode()

        try storage.storeUnsecured(privateInfoData: encoded, walletID: walletID)

        let result = try storage.getPrivateInfoData(for: walletID, auth: .none)

        #expect(result == encoded, "Stored data should match the original encoded data")
    }

    @Test
    func testUpdateAccessCodeSuccess() throws {
        let storage = makeStorage()

        let encoded = makePrivateInfo().encode()

        try storage.storeUnsecured(privateInfoData: encoded, walletID: walletID)
        try storage.updateAccessCode("accessCode", oldAuth: .none, for: walletID)

        try storage.updateAccessCode("newAccessCode", oldAuth: .accessCode("accessCode"), for: walletID)

        let result = try storage.getPrivateInfoData(for: walletID, auth: .accessCode("newAccessCode"))

        #expect(result == encoded, "Stored data should match the original encoded data")
    }

    @Test
    func testUpdateInvalidAccessCodeFail() throws {
        let storage = makeStorage()

        let encoded = makePrivateInfo().encode()

        try storage.storeUnsecured(privateInfoData: encoded, walletID: walletID)
        try storage.updateAccessCode("accessCode", oldAuth: .none, for: walletID)

        #expect(throws: Error.self, performing: {
            try storage.updateAccessCode("newAccessCode", oldAuth: .accessCode("invalidAccessCode"), for: walletID)
        })
    }

    @Test
    func testSetBiometricWithValidAccessCodeSuccess() throws {
        let storage = makeStorage()

        let encoded = makePrivateInfo().encode()

        try storage.storeUnsecured(privateInfoData: encoded, walletID: walletID)
        try storage.updateAccessCode("accessCode", oldAuth: .none, for: walletID)

        try storage.enableBiometrics(for: walletID, accessCode: "accessCode", context: LAContext())

        let result = try storage.getPrivateInfoData(for: walletID, auth: .biometrics(context: LAContext()))

        #expect(result == encoded, "Stored data should match the original encoded data")
    }

    @Test
    func testSetBiometricsWithInvalidAccessCodeFail() throws {
        let storage = makeStorage()

        let encoded = makePrivateInfo().encode()

        try storage.storeUnsecured(privateInfoData: encoded, walletID: walletID)
        try storage.updateAccessCode("accessCode", oldAuth: .none, for: walletID)

        #expect(throws: Error.self, performing: {
            try storage.enableBiometrics(for: walletID, accessCode: "invalidAccessCode", context: LAContext())
        })
    }

    @Test
    func testDeleteWalletSuccess() throws {
        let storage = makeStorage()

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

        #expect(throws: Error.self, performing: {
            try storage.delete(hotWalletID: walletID)
        })
    }
}
