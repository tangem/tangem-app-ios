//
//  DefaultMissing.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

@propertyWrapper
public struct DefaultIfMissing<T: Codable & DefaultValueProvider>: Codable {
    public let wrappedValue: T

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(T.self) {
            wrappedValue = value
        } else {
            wrappedValue = T.defaultValue
        }
    }

    public init(_ wrappedValue: T?) {
        self.wrappedValue = wrappedValue ?? T.defaultValue
    }

    public init() {
        wrappedValue = T.defaultValue
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue)
    }
}

public protocol DefaultValueProvider {
    static var defaultValue: Self { get }
}

extension Bool: DefaultValueProvider {
    public static var defaultValue: Bool { false }
}

public extension KeyedDecodingContainer {
    func decode<T: Codable & DefaultValueProvider>(_ type: DefaultIfMissing<T>.Type, forKey key: Key) throws -> DefaultIfMissing<T> {
        return try decodeIfPresent(type, forKey: key) ?? DefaultIfMissing(nil)
    }
}
