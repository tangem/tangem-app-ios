//
//  Testing+NewsTag.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//

import Testing

/// Use this tag for all news-related suites: @Suite(.tags(.news))
extension Tag {
    @Tag static var news: Self
}

actor NewsTestsDependencyIsolation {
    static let shared = NewsTestsDependencyIsolation()

    func run<T>(_ operation: () async throws -> T) async rethrows -> T {
        try await operation()
    }
}
