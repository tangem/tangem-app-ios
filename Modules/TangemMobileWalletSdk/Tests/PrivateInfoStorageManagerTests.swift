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
@testable import TangemMobileWalletSdk
@testable import TangemFoundation

struct PrivateInfoStorageManagerTests {
    private let walletID = UserWalletId(value: Data(hexString: "test"))

    private func makePrivateInfo() -> PrivateInfo {
        let passphrase = "test-passphrase"
        return PrivateInfo(entropy: entropy, passphrase: passphrase)
    }

    private func makeStorage(
        mockedSecureStorage: MockedSecureStorage = MockedSecureStorage(),
        mockedSecureEnclaveService: MobileWalletSecureEnclaveService = MockedSecureEnclaveService()
    ) -> PrivateInfoStorageManager {
        let mockedBiometricsSecureEnclaveService = MockedBiometricsSecureEnclaveService()
        let mockedBiometricsStorage = MockedBiometricsStorage()

        return PrivateInfoStorageManager(
            privateInfoStorage: PrivateInfoStorage(
                secureStorage: mockedSecureStorage,
                secureEnclaveService: mockedSecureEnclaveService
            ),
            encryptedSecureStorage: EncryptedSecureStorage(
                secureStorage: mockedSecureStorage,
                secureEnclaveService: mockedSecureEnclaveService
            ),
            encryptedBiometricsStorage: EncryptedBiometricsStorage(
                biometricsStorage: mockedBiometricsStorage,
                secureEnclaveBiometricsService: mockedBiometricsSecureEnclaveService
            )
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
    func testWrongAccessCodeIsReportedAsWrongAccessCode() throws {
        let storage = makeStorage()

        try storage.storeUnsecured(privateInfoData: makePrivateInfo().encode(), walletID: walletID)
        let context = try storage.validate(auth: .none, for: walletID)
        try storage.updateAccessCode("accessCode", context: context)

        #expect(throws: MobileWalletUnlockError.wrongAccessCode, performing: {
            try storage.validate(auth: .accessCode("newAccessCode"), for: walletID)
        })
    }

    @Test
    func testPurgedSecureEnclaveKeyIsNotReportedAsWrongAccessCode() throws {
        // Arrange: a wallet protected by an access code, stored while the Secure Enclave key still existed.
        let sharedSecureStorage = MockedSecureStorage()
        let storage = makeStorage(mockedSecureStorage: sharedSecureStorage)

        try storage.storeUnsecured(privateInfoData: makePrivateInfo().encode(), walletID: walletID)
        let context = try storage.validate(auth: .none, for: walletID)
        try storage.updateAccessCode("accessCode", context: context)

        // Act: the same keychain items, but the SE wrapping key is gone (device passcode was turned off).
        let storageAfterPurge = makeStorage(
            mockedSecureStorage: sharedSecureStorage,
            mockedSecureEnclaveService: MockedPurgedKeySecureEnclaveService()
        )

        // Assert: the correct code must surface a storage failure, not a wrong-code error…
        #expect(throws: MobileWalletUnlockError.keyStorageUnavailable, performing: {
            try storageAfterPurge.validate(auth: .accessCode("accessCode"), for: walletID)
        })

        // …while a genuinely wrong code is still reported as such (the password layer is checked first).
        #expect(throws: MobileWalletUnlockError.wrongAccessCode, performing: {
            try storageAfterPurge.validate(auth: .accessCode("wrongAccessCode"), for: walletID)
        })
    }

    @Test
    func testSetUpBiometric() throws {
        let storage = makeStorage()

        let encoded = makePrivateInfo().encode()

        try storage.storeUnsecured(privateInfoData: encoded, walletID: walletID)

        let context1 = try storage.validate(auth: .none, for: walletID)

        try storage.updateAccessCode("accessCode", enableBiometrics: true, context: context1)

        #expect(storage.isBiometricsEnabled(walletID: walletID) == true)
    }

    @Test
    func testSetUpBiometricWithValidAccessCodeSuccess() throws {
        let storage = makeStorage()

        let encoded = makePrivateInfo().encode()

        try storage.storeUnsecured(privateInfoData: encoded, walletID: walletID)

        let context1 = try storage.validate(auth: .none, for: walletID)

        try storage.updateAccessCode("accessCode", enableBiometrics: true, context: context1)

        let context2 = try storage.validate(auth: .accessCode("accessCode"), for: walletID)
        let context3 = try storage.validate(auth: .biometrics(context: LAContext()), for: walletID)

        let result1 = try storage.getPrivateInfoData(context: context2)
        let result2 = try storage.getPrivateInfoData(context: context3)

        #expect(result1 == encoded, "Stored data should match the original encoded data")
        #expect(result2 == encoded, "Stored data should match the original encoded data")
    }

    @Test
    func testSetUpBiometricsWithInvalidAccessCodeFail() throws {
        let storage = makeStorage()

        let encoded = makePrivateInfo().encode()

        try storage.storeUnsecured(privateInfoData: encoded, walletID: walletID)

        let context = try storage.validate(auth: .none, for: walletID)

        try storage.updateAccessCode("accessCode", enableBiometrics: true, context: context)

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
