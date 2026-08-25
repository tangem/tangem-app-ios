//
//  DeviceSignatureTests.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemBackendAuthentication

@Suite(.tags(.backendAuthentication))
struct DeviceSignatureTests {
    @Test
    func initSucceedsWithA64ByteRawRepresentation() throws {
        let rawRepresentation = Data(repeating: Self.placeholderByte, count: 64)

        let signature = try DeviceSignature(
            derRepresentation: Self.anyDerRepresentation,
            rawRepresentation: rawRepresentation
        )

        #expect(signature.derRepresentation == Self.anyDerRepresentation)
        #expect(signature.rawRepresentation == rawRepresentation)
    }

    @Test
    func initThrowsInvalidLengthWhenRawRepresentationIsEmpty() {
        let emptyRawRepresentation = Data()

        #expect(throws: DeviceSignature.RawRepresentationFormatError.invalidLength(actual: 0)) {
            try DeviceSignature(
                derRepresentation: Self.anyDerRepresentation,
                rawRepresentation: emptyRawRepresentation
            )
        }
    }

    @Test
    func initThrowsInvalidLengthWhenRawRepresentationIsTooShort() {
        let tooShortRawRepresentation = Data(repeating: Self.placeholderByte, count: 63)

        #expect(throws: DeviceSignature.RawRepresentationFormatError.invalidLength(actual: 63)) {
            try DeviceSignature(
                derRepresentation: Self.anyDerRepresentation,
                rawRepresentation: tooShortRawRepresentation
            )
        }
    }

    @Test
    func initThrowsInvalidLengthWhenRawRepresentationIsTooLong() {
        let tooLongRawRepresentation = Data(repeating: Self.placeholderByte, count: 65)

        #expect(throws: DeviceSignature.RawRepresentationFormatError.invalidLength(actual: 65)) {
            try DeviceSignature(
                derRepresentation: Self.anyDerRepresentation,
                rawRepresentation: tooLongRawRepresentation
            )
        }
    }
}

extension DeviceSignatureTests {
    private static let anyDerRepresentation = Data([0x01, 0x02, 0x03])
    private static let placeholderByte: UInt8 = 0xAB
}
