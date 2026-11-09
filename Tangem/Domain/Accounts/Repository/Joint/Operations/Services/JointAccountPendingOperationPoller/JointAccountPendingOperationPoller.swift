//
//  JointAccountPendingOperationPoller.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol JointAccountPendingOperationPoller {
    func requestFrequentUpdates() -> AnyCancellable?
}
