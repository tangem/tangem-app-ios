//
//  ALPH+AnySerde.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension ALPH {
    class AnySerde<T>: Serde {
        private let _serialize: (T) -> Data
        private let _deserialize: (Data) -> Result<T, Error>
        private let _deserializeWithRest: (Data) -> Result<Staging<T>, Error>

        init<U: Serde>(_ base: U) where U.Value == T {
            _serialize = base.serialize
            _deserialize = base.deserialize
            _deserializeWithRest = base._deserialize
        }

        func serialize(_ input: T) -> Data {
            return _serialize(input)
        }

        func deserialize(_ input: Data) -> Result<T, Error> {
            do {
                let value = try _deserializeWithRest(input).get().value
                return .success(value)
            } catch {
                return .failure(error)
            }
        }

        func _deserialize(_ input: Data) -> Result<Staging<T>, Error> {
            return _deserializeWithRest(input)
        }
    }
}
