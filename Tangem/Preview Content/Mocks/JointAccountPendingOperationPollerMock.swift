//
//  JointAccountPendingOperationPollerMock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class JointAccountPendingOperationPollerMock: JointAccountPendingOperationPoller {
    func requestFrequentUpdates() -> AnyCancellable? {
        AnyCancellable {}
    }
}
