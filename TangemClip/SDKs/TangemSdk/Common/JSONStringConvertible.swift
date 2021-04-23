//
//  JSONStringConvertible.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

/// The basic protocol for command response
public protocol JSONStringConvertible: Codable, CustomStringConvertible {}

extension JSONStringConvertible {
    public var description: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        encoder.dataEncodingStrategy = .custom{ data, encoder in
            var container = encoder.singleValueContainer()
            return try container.encode(data.asHexString())
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US")
        dateFormatter.dateStyle = .medium
        encoder.dateEncodingStrategy = .formatted(dateFormatter)
        let data = (try? encoder.encode(self)) ?? Data()
        return String(data: data, encoding: .utf8)!
    }
}
