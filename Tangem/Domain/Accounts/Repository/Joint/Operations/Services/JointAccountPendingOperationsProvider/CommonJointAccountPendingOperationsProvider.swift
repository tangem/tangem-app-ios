//
//  CommonJointAccountPendingOperationsProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

struct CommonJointAccountPendingOperationsProvider {}

// MARK: - JointAccountPendingOperationsProvider protocol conformance

extension CommonJointAccountPendingOperationsProvider: JointAccountPendingOperationsProvider {
    var pendingOperationsPublisher: AnyPublisher<[JointAccountPendingOperation], Never> {
        // [REDACTED_TODO_COMMENT]
        Just([]).eraseToAnyPublisher()
    }
}
