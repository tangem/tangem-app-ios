//
//  DevicePublicKeyTests.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemBackendAuthentication

@Suite(.tags(.backendAuthentication))
struct DevicePublicKeyTests {
    @Test
    func initSucceedsWithA65ByteUncompressedRawPoint() throws {
        let rawPoint = RawPointPrefix.Valid.uncompressed.bytes + Array(repeating: Self.placeholderByte, count: 64)

        let publicKey = try DevicePublicKey(derRepresentation: Self.anyDerRepresentation, rawPoint: rawPoint)

        #expect(publicKey.derRepresentation == Self.anyDerRepresentation)
        #expect(publicKey.rawPoint == rawPoint)
    }

    @Test
    func initThrowsInvalidLengthWhenRawPointIsEmpty() {
        let emptyRawPoint = Data()

        #expect(throws: DevicePublicKey.RawPointFormatError.invalidLength(actual: 0)) {
            try DevicePublicKey(derRepresentation: Self.anyDerRepresentation, rawPoint: emptyRawPoint)
        }
    }

    @Test
    func initThrowsInvalidLengthWhenRawPointIsTooShort() {
        let tooShortCoordinateBytes = Array(repeating: Self.placeholderByte, count: 63)
        let invalidRawPoint = RawPointPrefix.Valid.uncompressed.bytes + tooShortCoordinateBytes

        #expect(throws: DevicePublicKey.RawPointFormatError.invalidLength(actual: 64)) {
            try DevicePublicKey(derRepresentation: Self.anyDerRepresentation, rawPoint: invalidRawPoint)
        }
    }

    @Test
    func initThrowsInvalidLengthWhenRawPointIsTooLong() {
        let tooLongCoordinateBytes = Array(repeating: Self.placeholderByte, count: 65)
        let invalidRawPoint = RawPointPrefix.Valid.uncompressed.bytes + tooLongCoordinateBytes

        #expect(throws: DevicePublicKey.RawPointFormatError.invalidLength(actual: 66)) {
            try DevicePublicKey(derRepresentation: Self.anyDerRepresentation, rawPoint: invalidRawPoint)
        }
    }

    @Test(arguments: RawPointPrefix.Invalid.allCases.map(\.rawValue))
    func initThrowsInvalidPrefixWhenRawPointIsNotUncompressed(invalidPrefix: UInt8) {
        let invalidRawPoint = Data([invalidPrefix]) + Array(repeating: Self.placeholderByte, count: 64)

        #expect(throws: DevicePublicKey.RawPointFormatError.invalidPrefix(actual: invalidPrefix)) {
            try DevicePublicKey(derRepresentation: Self.anyDerRepresentation, rawPoint: invalidRawPoint)
        }
    }
}

extension DevicePublicKeyTests {
    private static let anyDerRepresentation = Data([0x01, 0x02, 0x03])
    private static let placeholderByte: UInt8 = 0xAB

    private enum RawPointPrefix {
        enum Valid: UInt8 {
            case uncompressed = 0x04

            var bytes: Data {
                Data([rawValue])
            }
        }

        enum Invalid: UInt8, CaseIterable {
            case pointAtInfinityMarker = 0x00
            case compressedPointEvenY = 0x02
            case compressedPointOddY = 0x03
            case arbitraryGarbageByte = 0xFF
        }
    }
}
