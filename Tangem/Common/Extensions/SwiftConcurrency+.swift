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
func runTask(_ code: @escaping () async throws -> Void) -> Task<Void, Error> {
    Task {
        try await code()
    }
}

@discardableResult
func runTask(_ code: @escaping () -> Void) -> Task<Void, Never> {
    Task {
        code()
    }
}

@discardableResult
func runTask<T: AnyObject>(in object: T, code: @escaping (T) async throws -> Void) -> Task<Void, Error> {
    Task { [weak object] in
        guard let object else { return }

        try await code(object)
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
