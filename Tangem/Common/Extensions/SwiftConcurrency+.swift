//
//  SwiftConcurrency+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

@discardableResult
func runTask(_ code: @escaping () async -> Void) -> Task<Void, Never> {
    Task {
        await code()
    }
}

@discardableResult
func runTask(_ code: @escaping () -> Void) -> Task<Void, Never> {
    Task {
        code()
    }
}

func runInTask<T>(_ code: @escaping () async throws -> T) async throws -> T {
    try await Task<T, Error> {
        try await code()
    }.value
}

func runInTask<T>(_ code: @escaping () async -> T) async throws -> T {
    try await Task<T, Error> {
        await code()
    }.value
}

@MainActor
func runOnMain(_ code: () -> Void) {
    code()
}

extension Task where Success == Never, Failure == Never {
    static func sleep(seconds: Double) async throws {
        let duration = UInt64(seconds * 1_000_000_000)
        try await Task.sleep(nanoseconds: duration)
    }
}
