//
//  KeyedDecodingContainer+.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

extension KeyedDecodingContainer {
    func decode<T: Decodable>(forKey key: K) throws -> T {
        return try decode(T.self, forKey: key)
    }

    func decode<T: Decodable>(forKey key: K, default value: T) throws -> T {
        return try decodeIfPresent(T.self, forKey: key) ?? value
    }

    func decodeIfPresent<T: Decodable>(forKey key: K) throws -> T? {
        return try decodeIfPresent(T.self, forKey: key)
    }
}
