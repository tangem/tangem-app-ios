//
//  ALPH+UnsignedTransactionSerde.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension ALPH {
    struct UnsignedTransactionSerde: Serde {
        typealias Value = UnsignedTransaction

        func serialize(_ input: UnsignedTransaction) -> Data {
            var data = Data()

            data.append(ByteSerde().serialize(input.version))
            data.append(NetworkId.serde.serialize(input.networkId))
            // null for scriptOpt: Option[StatefulScript]
            data.append(ByteSerde().serialize(Flags.noneB))
            data.append(GasBox.serde.serialize(input.gasAmount))
            data.append(U256Serde().serialize(input.gasPrice.value))
            data.append(AVectorSerde(TxInputDataSerde.serde).serialize(input.inputs))
            data.append(AVectorSerde(AssetOutputSerde()).serialize(input.fixedOutputs))

            return data
        }

        func _deserialize(_ input: Data) -> Result<Staging<UnsignedTransaction>, Error> {
            do {
                let pair0 = try ByteSerde()._deserialize(input).get()
                let pair1 = try NetworkId.serde._deserialize(pair0.rest).get()
                let pair2 = try ByteSerde()._deserialize(pair1.rest).get()
                let pair3 = try GasBox.serde._deserialize(pair2.rest).get()
                let pair4 = try U256Serde()._deserialize(pair3.rest).get()
                let pair5 = try AVectorSerde(TxInputDataSerde.serde)._deserialize(pair4.rest).get()
                let pair6 = try AVectorSerde(AssetOutputSerde())._deserialize(pair5.rest).get()

                let output = UnsignedTransaction(
                    version: pair0.value,
                    networkId: pair1.value,
                    gasAmount: pair3.value,
                    gasPrice: GasPrice(value: pair4.value),
                    inputs: pair5.value,
                    fixedOutputs: pair6.value
                )

                return .success(Staging(value: output, rest: pair6.rest))
            } catch {
                return .failure(error)
            }
        }
    }
}
