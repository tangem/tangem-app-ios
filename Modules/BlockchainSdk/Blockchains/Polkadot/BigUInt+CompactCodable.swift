//
//  BigUInt+CompactCodable.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
import ScaleCodec

extension BigUInt: @retroactive CompactCodable {
    public typealias UI = BigUInt

    public static var compactBitWidth: Int { 128 }

    public var compactBitsUsed: Int { bitWidth }

    public var trimmedLittleEndianData: Data { Data(serialize().reversed()) }

    public init?(trimmedLittleEndianData: Data) {
        self.init(littleEndian: trimmedLittleEndianData)
    }
}
