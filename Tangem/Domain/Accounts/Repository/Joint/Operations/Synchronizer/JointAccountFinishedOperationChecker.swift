//
//  JointAccountFinishedOperationChecker.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct JointAccountFinishedOperationChecker {
    func isFinished(_ operation: JointAccountOperation) -> Bool {
        !operation.status.isInFlight
    }
}
