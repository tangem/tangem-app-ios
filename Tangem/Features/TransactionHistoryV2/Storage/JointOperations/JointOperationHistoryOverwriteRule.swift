//
//  JointOperationHistoryOverwriteRule.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct JointOperationHistoryOverwriteRule {
    func shouldWrite(
        _ incoming: JointAccountOperationStatus,
        from source: Source,
        over stored: JointAccountOperationStatus?
    ) -> Bool {
        guard incoming != .unknown else {
            return false
        }

        switch source {
        case .remote:
            return true
        case .local:
            guard let stored,
                  !stored.isInFlight else {
                return true
            }

            return !incoming.isInFlight
        }
    }
}

// MARK: - Auxiliary types

extension JointOperationHistoryOverwriteRule {
    enum Source {
        case remote
        case local
    }
}
