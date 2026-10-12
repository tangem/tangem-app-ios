//
//  JointAccountPendingOperationsProviderMock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

struct JointAccountPendingOperationsProviderMock: JointAccountPendingOperationsProvider {
    var pendingOperationsPublisher: AnyPublisher<[JointAccountPendingOperation], Never> {
        Just([]).eraseToAnyPublisher()
    }
}
