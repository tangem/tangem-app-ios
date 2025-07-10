//
//  ALPH+CompactInteger+Mode.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension ALPH {
    enum ModeUtils {
        static let maskMode: Int = 0x3f
        static let maskRest: Int = 0xc0
        static let maskModeNeg: Int = 0xffffffc0

        static func decode(_ data: Data) -> Result<(Mode, Data, Data), Error> {
            guard let byte = data.first else {
                return .failure(SerdeError.incompleteData(expected: 1, got: 0))
            }

            let firstByte = Int(byte)

            switch firstByte & maskRest {
            case SingleByte.prefix:
                return .success((SingleByte(), data.prefix(1), data.dropFirst(1)))
            case TwoByte.prefix:
                return checkSize(data, expected: 2, mode: TwoByte())
            case FourByte.prefix:
                return checkSize(data, expected: 4, mode: FourByte())
            default:
                return checkSize(data, expected: Int(firstByte & maskMode) + 4 + 1, mode: MultiByte())
            }
        }

        private static func checkSize(_ bs: Data, expected: Int, mode: Mode) -> Result<(Mode, Data, Data), Error> {
            if bs.count >= expected {
                return .success((mode, bs.prefix(expected), bs.dropFirst(expected)))
            } else {
                return .failure(SerdeError.incompleteData(expected: expected, got: bs.count))
            }
        }
    }
}

// MARK: - Modes

extension ALPH {
    protocol Mode {
        static var prefix: Int { get }
        static var negPrefix: Int { get }
    }

    protocol FixedWidth: Mode {}

    struct SingleByte: FixedWidth {
        static let prefix: Int = 0x00 // 0b00000000
        static let negPrefix: Int = 0xc0 // 0b11000000
    }

    struct TwoByte: FixedWidth {
        static let prefix: Int = 0x40 // 0b01000000
        static let negPrefix: Int = 0x80 // 0b10000000
    }

    struct FourByte: FixedWidth {
        static let prefix: Int = 0x80 // 0b10000000
        static let negPrefix: Int = 0x40 // 0b01000000
    }

    struct MultiByte: Mode {
        static let prefix: Int = 0xc0 // 0b11000000
        static var negPrefix: Int {
            fatalError("Not needed at all")
        }
    }
}
