//
//  PotentCBOR+.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import PotentCBOR
import OrderedCollections

/// PotentCBOR supports ordered maps
extension CBOR {
    static func removingTag(_ tagToRemove: UInt64, from cbor: CBOR) -> CBOR {
        switch cbor {
        case .tagged(let tag, let value):
            if tag == Tag(rawValue: tagToRemove) {
                return removingTag(tagToRemove, from: value)
            } else {
                return .tagged(tag, removingTag(tagToRemove, from: value))
            }
        case .array(let array):
            return .array(array.map { removingTag(tagToRemove, from: $0) })
        case .map(let map):
            var ordered = OrderedDictionary<CBOR, CBOR>()
            for (key, value) in map {
                let newKey = removingTag(tagToRemove, from: key)
                let newValue = removingTag(tagToRemove, from: value)
                ordered[newKey] = newValue
            }
            return .map(ordered)
        default:
            return cbor
        }
    }
}
