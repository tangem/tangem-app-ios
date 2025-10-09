//
//  FlexibleDecimal.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

@propertyWrapper
public struct FlexibleDecimal: Decodable, Equatable {
    public var wrappedValue: Decimal?

    public init(wrappedValue: Decimal?) {
        self.wrappedValue = wrappedValue
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self.init(wrappedValue: nil)
            return
        }

        if let number = try? container.decode(Decimal.self) {
            self.init(wrappedValue: number)
            return
        }

        if let string = try? container.decode(String.self) {
            let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
            if let decimal = Decimal(string: trimmed) {
                self.init(wrappedValue: decimal)
                return
            }
        }

        self.init(wrappedValue: nil)
    }
}
