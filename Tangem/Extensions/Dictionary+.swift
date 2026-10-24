//
//  Dictionary+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

extension Dictionary {
    mutating func removeAll(where shouldBeRemoved: (_ pair: (key: Key, value: Value)) throws -> Bool) rethrows {
        try filter(shouldBeRemoved)
            .forEach { removeValue(forKey: $0.key) }
    }
}

extension Dictionary where Key == AnyHashable, Value == Any {
    func nonNullString(_ key: String) -> String? {
        guard let value = self[key] as? String, value != "null" else {
            return nil
        }

        return value
    }
}

extension Dictionary where Key == Analytics.ParameterKey, Value == String {
    mutating func enrich(with params: [Analytics.ParameterKey: String]) {
        merge(params, uniquingKeysWith: { old, _ in old })
    }
}
