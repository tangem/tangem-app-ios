//
//  LoadingValue.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

/// Enum to wrap a value loading process
enum LoadingValue<Value> {
    case loading
    case loaded(_ value: Value)
    case failedToLoad(error: Error)

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

    var error: Error? {
        if case .failedToLoad(let error) = self {
            return error
        }

        return nil
    }
}
