//
//  KeyValuePair.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemAssets

public struct KeyValuePairViewData {
    let key: Key
    let value: Value

    public init(key: Key, value: Value) {
        self.key = key
        self.value = value
    }
}

public extension KeyValuePairViewData {
    struct Key {
        let text: String
        let action: (@MainActor () -> Void)?

        public init(text: String, action: (@MainActor () -> Void)?) {
            self.text = text
            self.action = action
        }
    }

    struct Value {
        let text: String
        let icon: ImageType?

        public init(text: String, icon: ImageType?) {
            self.text = text
            self.icon = icon
        }
    }
}
