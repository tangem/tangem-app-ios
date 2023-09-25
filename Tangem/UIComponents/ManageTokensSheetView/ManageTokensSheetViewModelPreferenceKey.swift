//
//  ManageTokensSheetViewModelPreferenceKey.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct ManageTokensSheetViewModelPreferenceKey: PreferenceKey {
    struct Box: Equatable {
        let value: ManageTokensSheetViewModel

        static func == (lhs: Self, rhs: Self) -> Bool {
            // We care only about pointer equality here to satisfy `onPreferenceChange(_:perform:)` requirements
            return lhs.value === rhs.value
        }
    }

    typealias Value = Box?

    static var defaultValue: Value { nil }

    static func reduce(value: inout Value, nextValue: () -> Value) {
        value = value ?? nextValue()
    }
}
