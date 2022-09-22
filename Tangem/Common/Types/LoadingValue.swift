//
//  LoadingValue.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

/// A simple enum to wrap a value to two states
enum LoadingValue<Value> {
    case loading
    case loaded(_ value: Value)

    var isLoading: Bool {
        if case .loading = self {
            return true
        }

        return false
    }

    var value: Value? {
        if case .loaded(let value) = self {
            return value
        }

        return nil
    }
}
