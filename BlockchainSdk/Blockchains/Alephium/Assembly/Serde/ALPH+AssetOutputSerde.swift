//
//  ALPH+AssetOutputSerde.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension ALPH {
    struct AssetOutputSerde: Serde {
        typealias Value = AssetOutput

        private let tokenTupleSerde = Tuple2Serde(serdeA0: TokenIdSerde(), serdeA1: U256Serde())

        func serialize(_ input: ALPH.AssetOutput) -> Data {
            var data = Data()
            data.append(U256Serde().serialize(input.amount))
            data.append(LockupScriptSerde().serialize(input.lockupScript))
            data.append(TimeStampSerde().serialize(input.lockTime))
            data.append(AVectorSerde(tokenTupleSerde).serialize(input.tokens))
            data.append(DataSerde().serialize(input.additionalData))
            return data
        }

        func _deserialize(_ input: Data) -> Result<ALPH.Staging<ALPH.AssetOutput>, Error> {
            do {
                let pair0 = try U256Serde()._deserialize(input).get()
                let pair1 = try LockupScriptSerde()._deserialize(pair0.rest).get()
                let pair2 = try TimeStampSerde()._deserialize(pair1.rest).get()
                let pair3 = try AVectorSerde(tokenTupleSerde)._deserialize(pair2.rest).get()
                let pair4 = try DataSerde()._deserialize(pair3.rest).get()

                let value = AssetOutput(
                    amount: pair0.value,
                    lockupScript: pair1.value,
                    lockTime: pair2.value,
                    tokens: pair3.value,
                    additionalData: pair4.value
                )

                return .success(Staging(value: value, rest: pair4.value))
            } catch {
                return .failure(error)
            }
        }
    }
}
