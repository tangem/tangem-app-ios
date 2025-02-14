//
//  LossyArray.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

@propertyWrapper
public struct LossyArray<T> {
    public var wrappedValue: [T]

    public init(wrappedValue: [T]) {
        self.wrappedValue = wrappedValue
    }
}

extension LossyArray: Decodable where T: Decodable {
    private struct AnyDecodableValue: Decodable {}

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()

        var elements: [T] = []
        while !container.isAtEnd {
            do {
                let value = try container.decode(T.self)
                elements.append(value)
            } catch {
                _ = try? container.decode(AnyDecodableValue.self)
            }
        }

        wrappedValue = elements
    }
}

extension LossyArray: Encodable where T: Encodable {
    public func encode(to encoder: Encoder) throws {
        try wrappedValue.encode(to: encoder)
    }
}

extension LossyArray: Equatable where T: Equatable {}
extension LossyArray: Hashable where T: Hashable {}
