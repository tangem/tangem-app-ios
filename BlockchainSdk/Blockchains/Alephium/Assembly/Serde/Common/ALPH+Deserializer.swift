//
//  Alephium+Deserializer.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension ALPH {
    protocol Deserializer {
        associatedtype T

        func deserialize(_ input: Data) throws -> T
        func _deserialize(_ input: Data) throws -> Staging<T>
    }
}

// MARK: - Implementation

extension ALPH.Deserializer {
    func validateGet<T, U>(_ get: @escaping (T) -> U?, error: @escaping (T) -> String) -> any ALPH.Deserializer {
        ALPH.DeserializerWrapper { input in
            try self._deserialize(input)
        }
    }
}

extension ALPH {
    struct DeserializerWrapper<U>: Deserializer {
        typealias T = U

        let deserializeFunc: (Data) throws -> Staging<T>

        func _deserialize(_ input: Data) throws -> Staging<T> {
            try deserializeFunc(input)
        }

        func deserialize(_ input: Data) throws -> U {
            try deserializeFunc(input).value
        }
    }
}
