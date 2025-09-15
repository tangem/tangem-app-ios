//
//  NotSupportedYieldModuleManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

struct NotSupportedYieldModuleManager: YieldModuleManager {
    var yieldWalletManagers: [TokenItem: YieldModuleWalletManager] { [:] }
    var yieldWalletManagersPublisher: AnyPublisher<[TokenItem: YieldModuleWalletManager], Never> {
        Empty().eraseToAnyPublisher()
    }
}
