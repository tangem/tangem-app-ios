//
//  JointAccountExpiredOperationChecker.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct JointAccountExpiredOperationChecker {
    private let finishedOperationChecker = JointAccountFinishedOperationChecker()

    func isExpired(_ operation: JointAccountOperation, now: Date) -> Bool {
        guard finishedOperationChecker.isFinished(operation), let finishedAt = operation.finishedAt else {
            return false
        }

        return finishedAt.addingTimeInterval(Constants.finishedOperationLifetime) <= now
    }
}

// MARK: - Constants

private extension JointAccountExpiredOperationChecker {
    enum Constants {
        static let finishedOperationLifetime: TimeInterval = 24 * 60 * 60
    }
}
