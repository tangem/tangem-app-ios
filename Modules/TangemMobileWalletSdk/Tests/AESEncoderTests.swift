//
//  BLSUtilTests.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//
import Testing
@testable import TangemMobileWalletSdk
import Foundation

struct AESEncoderTests {
    @Test
    func testEncryptDecryptWithPassword() throws {
        let password = "TestPassword123!"
        let originalData = try #require("Sensitive data to encrypt".data(using: .utf8))

        let encrypted = try AESEncoder.encryptWithPassword(password: password, content: originalData)
        let decrypted = try AESEncoder.decryptWithPassword(password: password, encryptedData: encrypted)

        #expect(decrypted == originalData)
    }

    @Test
    func testStaticDecrypt() throws {
        let password = "TestPassword123!"
        let originalData = try #require("Sensitive data to encrypt".data(using: .utf8))
        let encrypted = Data(hexString: "0100000010A0B3423186000E746C1F14D1C5277175000000360C4A43E55A11954714DF9FA58CD6B35527D15029CE36F91D397CA0CF21F6AC1AB529741C6CADCCADD3C5887EA294EC133A4A70B8BA73")
        let decrypted = try AESEncoder.decryptWithPassword(password: password, encryptedData: encrypted)
        #expect(decrypted == originalData)
    }

    @Test
    func testEncryptDecryptAES() throws {
        let key = Data((0 ..< 32).map { _ in UInt8.random(in: 0 ... 255) })
        let data = "Another secret message".data(using: .utf8)!
        let aad = "AssociatedData".data(using: .utf8)!

        let encrypted = try AESEncoder.encryptAES(rawEncryptionKey: key, rawData: data, associatedData: aad)
        let decrypted = try AESEncoder.decryptAES(rawEncryptionKey: key, encryptedData: encrypted, associatedData: aad)

        #expect(decrypted == data)
    }

    @Test
    func testDecryptWithWrongPasswordFails() throws {
        let password = "CorrectPassword"
        let wrongPassword = "WrongPassword"
        let data = "Secret".data(using: .utf8)!

        let encrypted = try AESEncoder.encryptWithPassword(password: password, content: data)

        #expect(throws: Error.self, "Decryption should fail with wrong password", performing: {
            try AESEncoder.decryptWithPassword(password: wrongPassword, encryptedData: encrypted)
        })
    }

    @Test
    func testDecryptWithWrongKeyFails() throws {
        let key = Data((0 ..< 32).map { _ in UInt8.random(in: 0 ... 255) })
        let wrongKey = Data((0 ..< 32).map { _ in UInt8.random(in: 0 ... 255) })
        let data = "Secret".data(using: .utf8)!
        let encrypted = try AESEncoder.encryptAES(rawEncryptionKey: key, rawData: data)

        #expect(throws: Error.self, "Decryption should fail with wrong key", performing: {
            try AESEncoder.decryptAES(rawEncryptionKey: wrongKey, encryptedData: encrypted)
        })
    }
}
