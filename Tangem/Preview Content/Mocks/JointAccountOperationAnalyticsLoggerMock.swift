//
//  JointAccountOperationAnalyticsLoggerMock.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct JointAccountOperationAnalyticsLoggerMock: JointAccountOperationAnalyticsLogger {
    func logOperationSigned(_ operation: JointAccountOperation) {}

    func logSigningFailed(error: Error) {}

    func logRejectionFailed(error: Error, isInitiator: Bool) {}
}
