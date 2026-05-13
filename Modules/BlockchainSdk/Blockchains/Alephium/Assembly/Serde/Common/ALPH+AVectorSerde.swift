//
//  ALPH+AVectorSerde.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension ALPH {
    struct AVectorSerde<T>: Serde {
        typealias Value = AVector<T>

        private let _serialize: (T) -> Data
        private let _deserialize: (Data) -> Result<T, Error>
        private let _deserializeWithRest: (Data) -> Result<Staging<T>, Error>

        init<U: Serde>(_ base: U) where U.Value == T {
            _serialize = base.serialize
            _deserialize = base.deserialize
            _deserializeWithRest = base._deserialize
        }

        func serialize(_ input: AVector<T>) -> Data {
            var data = Data()
            let sizeData = IntSerde().serialize(input.count)
            data.append(sizeData)

            for item in input {
                data.append(_serialize(item))
            }

            return data
        }

        func _deserialize(_ input: Data) -> Result<ALPH.Staging<ALPH.AVector<T>>, Error> {
            switch IntSerde()._deserialize(input) {
            case .success(let staging):
                return _deserialize(staging.rest)
            case .failure(let error):
                return .failure(error)
            }
        }
    }
}
