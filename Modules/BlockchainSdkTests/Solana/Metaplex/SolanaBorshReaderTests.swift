//
//  SolanaBorshReaderTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import BlockchainSdk

struct SolanaBorshReaderTests {
    @Test
    func readsLittleEndianIntegers() throws {
        var reader = SolanaBorshReader(data: Data([0x01, 0x34, 0x12, 0x78, 0x56, 0x34, 0x12, 0x08, 0x07, 0x06, 0x05, 0x04, 0x03, 0x02, 0x01]))

        #expect(try reader.readUInt8() == 0x01)
        #expect(try reader.readUInt16() == 0x1234)
        #expect(try reader.readUInt32() == 0x1234_5678)
        #expect(try reader.readUInt64() == 0x0102_0304_0506_0708)
        #expect(reader.isAtEnd)
    }

    @Test
    func readsOptionsAndSkipsStrings() throws {
        var reader = SolanaBorshReader(data: Data([0x00, 0x01, 0x2A, 0x03, 0x00, 0x00, 0x00, 0x61, 0x62, 0x63, 0x01]))

        #expect(try reader.readOption { try $0.readUInt8() } == nil)
        #expect(try reader.readOption { try $0.readUInt8() } == 0x2A)
        try reader.skipString()
        #expect(try reader.readBool())
    }

    @Test
    func readsVectors() throws {
        var reader = SolanaBorshReader(data: Data([0x02, 0x00, 0x00, 0x00, 0x0A, 0x0B]))
        var elements: [UInt8] = []

        try reader.readVector { elements.append(try $0.readUInt8()) }

        #expect(elements == [0x0A, 0x0B])
    }

    @Test
    func startsAtTheGivenOffset() throws {
        var reader = SolanaBorshReader(data: Data([0xFF, 0x2A]), offset: 1)

        #expect(try reader.readUInt8() == 0x2A)
    }

    @Test
    func failsPastTheEnd() {
        var reader = SolanaBorshReader(data: Data([0x01, 0x02]))

        #expect(throws: SolanaBorshReaderError.unexpectedEnd) {
            try reader.readUInt32()
        }
    }

    @Test
    func failsOnAStringLongerThanTheData() {
        var reader = SolanaBorshReader(data: Data([0xFF, 0xFF, 0xFF, 0xFF, 0x61]))

        #expect(throws: SolanaBorshReaderError.unexpectedEnd) {
            try reader.skipString()
        }
    }

    @Test
    func rejectsInvalidTags() {
        var optionReader = SolanaBorshReader(data: Data([0x02]))
        var boolReader = SolanaBorshReader(data: Data([0x02]))

        #expect(throws: SolanaBorshReaderError.invalidOptionTag) {
            try optionReader.readOption { try $0.readUInt8() }
        }
        #expect(throws: SolanaBorshReaderError.invalidBool) {
            try boolReader.readBool()
        }
    }
}
