//
//  ALPH+TokenIdSerde.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension ALPH {
    struct TokenIdSerde: Serde {
        typealias Value = TokenId

        func serialize(_ input: TokenId) -> Data {
            return Blake2b.serde.serialize(.init(bytes: input.value))
        }

        func _deserialize(_ input: Data) -> Result<ALPH.Staging<Value>, Error> {
            do {
                let staging = try Blake2b.serde._deserialize(input).get()
                return .success(Staging(value: TokenId(value: staging.value.bytes), rest: staging.rest))
            } catch {
                return .failure(error)
            }
        }
    }
}
