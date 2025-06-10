//
//  ALPH+Tuple2Serde.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension ALPH {
    struct Tuple2<A0, A1> {
        let a0: A0
        let a1: A1

        init(a0: A0, a1: A1) {
            self.a0 = a0
            self.a1 = a1
        }
    }

    struct Product2<A0, A1, T>: Serde {
        typealias Value = T

        let pack: (A0, A1) -> T
        let unpack: (T) -> Tuple2<A0, A1>
        let serdeA0: AnySerde<A0>
        let serdeA1: AnySerde<A1>

        init(pack: @escaping (A0, A1) -> T, unpack: @escaping (T) -> Tuple2<A0, A1>, serdeA0: AnySerde<A0>, serdeA1: AnySerde<A1>) {
            self.pack = pack
            self.unpack = unpack
            self.serdeA0 = serdeA0
            self.serdeA1 = serdeA1
        }

        func serialize(_ input: T) -> Data {
            let unpacked = unpack(input)
            var data = Data()
            data.append(serdeA0.serialize(unpacked.a0))
            data.append(serdeA1.serialize(unpacked.a1))
            return data
        }

        func _deserialize(_ input: Data) -> Result<Staging<Value>, Error> {
            do {
                let pair0 = try serdeA0._deserialize(input).get()
                let pair1 = try serdeA1._deserialize(input).get()

                let value = pack(pair0.value, pair1.value)
                return .success(Staging(value: value, rest: pair1.rest))
            } catch {
                return .failure(error)
            }
        }
    }

    struct Tuple2Serde<A0: Serde, A1: Serde>: Serde {
        typealias Value = (A0.Value, A1.Value)

        let serdeA0: AnySerde<A0.Value>
        let serdeA1: AnySerde<A1.Value>

        init(serdeA0: A0, serdeA1: A1) {
            self.serdeA0 = AnySerde<A0.Value>(serdeA0)
            self.serdeA1 = AnySerde<A1.Value>(serdeA1)
        }

        func serialize(_ input: (A0.Value, A1.Value)) -> Data {
            var output = Data()
            output.append(serdeA0.serialize(input.0))
            output.append(serdeA1.serialize(input.1))
            return output
        }

        func _deserialize(_ input: Data) -> Result<ALPH.Staging<(A0.Value, A1.Value)>, Error> {
            do {
                let pair0 = try serdeA0._deserialize(input).get()
                let pair1 = try serdeA1._deserialize(pair0.rest).get()

                let result = Staging(value: (pair0.value, pair1.value), rest: pair1.rest)
                return .success(result)
            } catch {
                return .failure(error)
            }
        }
    }
}
