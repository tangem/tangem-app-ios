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
            encryptionKeySecureStorage: EncryptedSecureStorage(
                secureStorage: mockedSecureStorage,
                secureEnclaveService: mockedSecureEnclaveService
            ),
            encryptionKeyBiometricsStorage: EncryptedBiometricsStorage(biometricsStorage: mockedBiometricsStorage, secureEnclaveServiceType: MockedSecureEnclaveService.self)
        )
    }

    @Test
    func testCreateUnsecured() throws {
        let storage = makeStorage()

        let encoded = makePrivateInfo().encode()

        try storage.storeUnsecured(privateInfoData: encoded, walletID: walletID)

        let context = try storage.validate(auth: .none, for: walletID)

        let result = try storage.getPrivateInfoData(context: context)

        #expect(result == encoded, "Stored data should match the original encoded data")
    }

    @Test
    func testUpdateAccessCodeSuccess() throws {
        let storage = makeStorage()

        let encoded = makePrivateInfo().encode()

        try storage.storeUnsecured(privateInfoData: encoded, walletID: walletID)

        let context1 = try storage.validate(auth: .none, for: walletID)

        try storage.updateAccessCode("accessCode", context: context1)

        let context2 = try storage.validate(auth: .accessCode("accessCode"), for: walletID)

        try storage.updateAccessCode("newAccessCode", context: context2)

        let context3 = try storage.validate(auth: .accessCode("newAccessCode"), for: walletID)

        let result = try storage.getPrivateInfoData(context: context3)

        #expect(result == encoded, "Stored data should match the original encoded data")
    }

    @Test
    func testUpdateInvalidAccessCodeFail() throws {
        let storage = makeStorage()

        let encoded = makePrivateInfo().encode()

        try storage.storeUnsecured(privateInfoData: encoded, walletID: walletID)

        let context = try storage.validate(auth: .none, for: walletID)

        try storage.updateAccessCode("accessCode", context: context)

        #expect(throws: Error.self, performing: {
            try storage.validate(auth: .accessCode("newAccessCode"), for: walletID)
        })
    }

    @Test
    func testSetBiometricWithValidAccessCodeSuccess() throws {
        let storage = makeStorage()

        let encoded = makePrivateInfo().encode()

        try storage.storeUnsecured(privateInfoData: encoded, walletID: walletID)

        let context1 = try storage.validate(auth: .none, for: walletID)

        try storage.updateAccessCode("accessCode", context: context1)

        let context2 = try storage.validate(auth: .accessCode("accessCode"), for: walletID)

        try storage.enableBiometrics(context: context2, laContext: LAContext())

        let context3 = try storage.validate(auth: .biometrics(context: LAContext()), for: walletID)

        let result = try storage.getPrivateInfoData(context: context3)

        #expect(result == encoded, "Stored data should match the original encoded data")
    }

    @Test
    func testSetBiometricsWithInvalidAccessCodeFail() throws {
        let storage = makeStorage()

        let encoded = makePrivateInfo().encode()

        try storage.storeUnsecured(privateInfoData: encoded, walletID: walletID)

        let context = try storage.validate(auth: .none, for: walletID)

        try storage.updateAccessCode("accessCode", context: context)

        #expect(throws: Error.self, performing: {
            _ = try storage.validate(auth: .accessCode("invalidAccessCode"), for: walletID)
        })
    }

    @Test
    func testDeleteWalletSuccess() throws {
        let storage = makeStorage()

        let encoded = makePrivateInfo().encode()

        try storage.storeUnsecured(privateInfoData: encoded, walletID: walletID)
        try storage.delete(walletID: walletID)

        #expect(throws: Error.self, performing: {
            _ = try storage.validate(auth: .biometrics(context: LAContext()), for: walletID)
        })

        #expect(throws: Error.self, performing: {
            _ = try storage.validate(auth: .none, for: walletID)
        })
    }

    @Test
    func testDeleteWalletFailure() throws {
        let storage = makeStorage()

        #expect(throws: Error.self, performing: {
            try storage.delete(walletID: walletID)
        })
    }
}
