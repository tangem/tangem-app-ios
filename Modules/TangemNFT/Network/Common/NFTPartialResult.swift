//
//  NFTPartialResult.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

public struct NFTPartialResult<T: Equatable>: Equatable {
    public let value: T
    public let errors: [NFTErrorDescriptor]

    public var hasErrors: Bool {
        !errors.isEmpty
    }

    public init(value: T, errors: [NFTErrorDescriptor] = []) {
        self.value = value
        self.errors = errors
    }

    public static func == (lhs: NFTPartialResult, rhs: NFTPartialResult) -> Bool {
        lhs.value == rhs.value &&
            lhs.hasErrors == rhs.hasErrors
    }
}

public struct NFTErrorDescriptor: Equatable {
    public let code: Int
    public let description: String

    public init(code: Int, description: String) {
        self.code = code
        self.description = description
    }
}
