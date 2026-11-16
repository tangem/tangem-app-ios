//
//  Task+WaitForCompletion.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension Task where Failure == Never {
    func waitForCompletion() async throws {
        await withTaskCancellationHandler {
            _ = await value
        } onCancel: {
            cancel()
        }

        try Task<Never, Never>.checkCancellation()
    }
}
