//
//  NFTPartialResult.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

public struct NFTPartialResult<T: Equatable>: Equatable {
    public let value: T
    public let hasErrors: Bool

    public init(value: T, hasErrors: Bool = false) {
        self.value = value
        self.hasErrors = hasErrors
    }
}
