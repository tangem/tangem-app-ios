//
//  DeviceSignaturePayloadFactoryTests.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct Foundation.Data
import Testing
@testable import TangemBackendAuthentication

@Suite(.tags(.backendAuthentication))
struct DeviceSignaturePayloadFactoryTests {
    @Test
    func makeJoinsAllFieldsInOrderWithColons() throws {
        let devicePublicKey = try DevicePublicKey.fake
        let metadata = DeviceMetadata(
            deviceModel: "iPhone 15 Pro",
            os: "iOS",
            osVersion: "17.4.1",
            appVersion: "5.12.0",
            userAgent: "Tangem/5.12.0 (iOS 17.4.1; iPhone 15 Pro)",
            locale: "en-US",
            timezone: "America/New_York"
        )

        let payload = DeviceSignaturePayloadFactory.make(
            devicePublicKey: devicePublicKey,
            decryptedNonce: "decrypted-nonce",
            attestationToken: Data([0xAA, 0xBB]),
            metadata: metadata
        )

        let expected = [
            devicePublicKey.derRepresentation.base64EncodedString(),
            "decrypted-nonce",
            Data([0xAA, 0xBB]).base64EncodedString(),
            "iPhone 15 Pro",
            "iOS",
            "17.4.1",
            "5.12.0",
            "Tangem/5.12.0 (iOS 17.4.1; iPhone 15 Pro)",
            "en-US",
            "America/New_York",
        ].joined(separator: ":")

        #expect(String(decoding: payload, as: UTF8.self) == expected)
    }

    @Test
    func makeLeavesAnEmptySegmentWhenAttestationTokenIsNil() throws {
        let devicePublicKey = try DevicePublicKey.fake
        let metadata = DeviceMetadata(
            deviceModel: "iPhone 15 Pro",
            os: "iOS",
            osVersion: "17.4.1",
            appVersion: "5.12.0",
            userAgent: "Tangem/5.12.0 (iOS 17.4.1; iPhone 15 Pro)",
            locale: "en-US",
            timezone: "America/New_York"
        )

        let payload = DeviceSignaturePayloadFactory.make(
            devicePublicKey: devicePublicKey,
            decryptedNonce: "decrypted-nonce",
            attestationToken: nil,
            metadata: metadata
        )

        let expected = [
            devicePublicKey.derRepresentation.base64EncodedString(),
            "decrypted-nonce",
            "",
            "iPhone 15 Pro",
            "iOS",
            "17.4.1",
            "5.12.0",
            "Tangem/5.12.0 (iOS 17.4.1; iPhone 15 Pro)",
            "en-US",
            "America/New_York",
        ].joined(separator: ":")

        #expect(String(decoding: payload, as: UTF8.self) == expected)
    }
}
