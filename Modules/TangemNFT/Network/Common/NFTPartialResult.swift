//
//  NFTPartialResult.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemFoundation

// MARK: - NFTPartialResult

public struct NFTPartialResult<T: Equatable & Hashable & Sendable>: Equatable, Hashable, Sendable {
    public let value: T
    public let errors: [NFTErrorDescriptor]

    public var hasErrors: Bool {
        errors.isNotEmpty
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

// MARK: - NFTErrorDescriptor

public struct NFTErrorDescriptor: Equatable, Hashable, Sendable {
    public let code: Int
    public let description: String

    public init(code: Int, description: String) {
        self.code = code
        self.description = description
    }
}

// MARK: - Extensions

extension NFTPartialResult where T == [NFTCollection] {
    var assetsOrCollectionHadErrorsUpdating: Bool {
        hasErrors || value.contains { $0.assetsResult.hasErrors }
    }
}

extension NFTPartialResult: ExpressibleByArrayLiteral where T: ExpressibleByArrayLiteral, T: RangeReplaceableCollection {
    public init(arrayLiteral elements: T.Element...) {
        self.init(value: T(elements), errors: [])
    }
}
