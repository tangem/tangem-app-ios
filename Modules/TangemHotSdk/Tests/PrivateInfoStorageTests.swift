//
//  File.swift
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
            secureEnclaveService: MockedSecureEnclaveService()
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
    func testUpdatePasscodeSuccess() throws {
        let storage = makeStorage()
        let walletID = HotWalletID()
        
        let encoded = makePrivateInfo().encode()
        
        try storage.storeUnsecured(privateInfoData: encoded, walletID: walletID)
        try storage.updatePasscode("passcode", oldAuth: nil, for: walletID)
        
        try storage.updatePasscode("newPasscode", oldAuth: .passcode("passcode"), for: walletID)
        
        let result = try storage.getPrivateInfoData(for: walletID, auth: .passcode("newPasscode"))
        
        #expect(result == encoded, "Stored data should match the original encoded data")
    }
    
    @Test
    func testUpdateInvalidPasscodeFail() throws {
        let storage = makeStorage()
        let walletID = HotWalletID()
        
        let encoded = makePrivateInfo().encode()
        
        try storage.storeUnsecured(privateInfoData: encoded, walletID: walletID)
        try storage.updatePasscode("passcode", oldAuth: nil, for: walletID)
        
        #expect(throws: Error.self, performing: {
            try storage.updatePasscode("newPasscode", oldAuth: .passcode("invalidPasscode"), for: walletID)
        })
    }
    
    @Test
    func testSetBiometricWithValidPasscodeSuccess() throws {
        let storage = makeStorage()
        let walletID = HotWalletID()
        
        let encoded = makePrivateInfo().encode()
        
        try storage.storeUnsecured(privateInfoData: encoded, walletID: walletID)
        try storage.updatePasscode("passcode", oldAuth: nil, for: walletID)
        
        try storage.enableBiometrics(for: walletID, passcode: "passcode", context: LAContext())
        
        let result = try storage.getPrivateInfoData(for: walletID, auth: .biometrics(context: LAContext()))
        
        #expect(result == encoded, "Stored data should match the original encoded data")
    }
    
    @Test
    func testSetBiometricsWithInvalidPasscodeFail() throws {
        let storage = makeStorage()
        let walletID = HotWalletID()
        
        let encoded = makePrivateInfo().encode()
        
        try storage.storeUnsecured(privateInfoData: encoded, walletID: walletID)
        try storage.updatePasscode("passcode", oldAuth: nil, for: walletID)
        
        #expect(throws: Error.self, performing: {
            try storage.enableBiometrics(for: walletID, passcode: "invalidPasscode", context: LAContext())
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
