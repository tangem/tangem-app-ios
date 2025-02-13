//
//  ALPH+Serde.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

// MARK: - Serde Protocol

extension ALPH {
    protocol Serde {
        associatedtype Value

        func serialize(_ input: Value) -> Data
        func deserialize(_ input: Data) -> Result<Value, Error>
        func _deserialize(_ input: Data) -> Result<Staging<Value>, Error>
    }
}

extension ALPH.Serde {
    func deserialize(_ input: Data) -> Result<Value, Error> {
        do {
            let staging = try _deserialize(input).get()

            if staging.rest.isEmpty {
                return .success(staging.value)
            } else {
                return .failure(ALPH.SerdeError.redundant(expected: input.count - staging.rest.count, got: input.count))
            }
        } catch {
            return .failure(error)
        }
    }
}

extension ALPH.Serde {
    func xmap<S>(to: @escaping (Value) -> S, from: @escaping (S) -> Value) -> ALPH.AnySerde<S> {
        let parentSerde = ALPH.AnySerde(self)
        return ALPH.AnySerde(ALPH.XMappedSerde(parent: parentSerde, to: to, from: from))
    }

    func xfmap<S>(to: @escaping (Value) -> Result<S, Error>, from: @escaping (S) -> Value) -> ALPH.AnySerde<S> {
        let parentSerde = ALPH.AnySerde(self)
        return ALPH.AnySerde(ALPH.XFMapSerde(parent: parentSerde, to: to, from: from))
    }

    func xomap<S>(to: @escaping (Value) -> S?, from: @escaping (S) -> Value) -> ALPH.AnySerde<S> {
        return xfmap(
            to: { t in
                if let mapped = to(t) {
                    return .success(mapped)
                } else {
                    return .failure(ALPH.SerdeError.validation(message: "Validation error"))
                }
            },
            from: from
        )
    }
}

extension ALPH {
    struct XMappedSerde<T, S>: Serde {
        let parent: ALPH.AnySerde<T>
        let to: (T) -> S
        let from: (S) -> T

        func serialize(_ input: S) -> Data {
            return parent.serialize(from(input))
        }

        func deserialize(_ input: Data) -> Result<S, Error> {
            return parent.deserialize(input).map(to)
        }

        func _deserialize(_ input: Data) -> Result<Staging<S>, Error> {
            return parent._deserialize(input).map { staging in
                Staging(value: to(staging.value), rest: staging.rest)
            }
        }
    }

    struct XFMapSerde<T, S>: Serde {
        let parent: ALPH.AnySerde<T>
        let to: (T) -> Result<S, Error>
        let from: (S) -> T

        func serialize(_ input: S) -> Data {
            return parent.serialize(from(input))
        }

        func deserialize(_ input: Data) -> Result<S, Error> {
            return parent.deserialize(input).flatMap(to)
        }

        func _deserialize(_ input: Data) -> Result<Staging<S>, Error> {
            return parent._deserialize(input).flatMap { staging in
                to(staging.value).map { mappedValue in
                    Staging(value: mappedValue, rest: staging.rest)
                }
            }
        }
    }
}
