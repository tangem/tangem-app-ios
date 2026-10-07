//
//  KeyedTaskProcessor.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Runs one task per key and hands its result to every caller asking for that key while it is in
/// flight. The shared task is never cancelled on a caller's behalf.
actor KeyedTaskProcessor<Key: Hashable & Sendable, Success: Sendable> {
    private var tasks: [Key: Task<Success, Error>] = [:]

    func execute(forKey key: Key, action: @escaping @Sendable () async throws -> Success) async throws -> Success {
        if let task = tasks[key] {
            return try await task.value
        }

        let task = Task {
            // Nothing else writes this key while the task runs, so the entry it clears is its own.
            defer { tasks[key] = nil }

            return try await action()
        }

        tasks[key] = task

        return try await task.value
    }
}
