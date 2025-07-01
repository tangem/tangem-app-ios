//
//  FlexibleDecimal.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

/// Unfortunately some APIs (e.g. Blockaid) could put both String and Number types inside the same JSON field
/// This allows parsing Decimal from both types
@propertyWrapper
public struct FlexibleDecimal: Decodable {
    public var wrappedValue: Decimal?

    /// Allow usage like `@FlexibleDecimal var x: Decimal?`
    public init(wrappedValue: Decimal?) {
        self.wrappedValue = wrappedValue
    }

    /// Decode from JSON (number, string, or nil) — never throws on bad shape.
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value: Decimal?

        if container.decodeNil() {
            value = nil
        } else if let dec = try? container.decode(Decimal.self) {
            value = dec
        } else if let str = try? container.decode(String.self),
                  let dec = Decimal(string: str) {
            value = dec
        } else {
            value = nil
        }

        // MUST call your own init(wrappedValue:) here:
        self.init(wrappedValue: value)
    }
}
