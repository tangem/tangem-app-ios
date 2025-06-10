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
    public var wrappedValue: Decimal

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let decimal = try? container.decode(Decimal.self) {
            wrappedValue = decimal
        } else if let string = try? container.decode(String.self),
                  let decimal = Decimal(string: string) {
            wrappedValue = decimal
        } else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [],
                    debugDescription: "Expected a decimal or a string representing a decimal."
                )
            )
        }
    }
}
