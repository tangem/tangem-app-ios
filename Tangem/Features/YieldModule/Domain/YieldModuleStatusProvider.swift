//
//  YieldModuleStatusProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine

protocol YieldModuleStatusProvider: AnyObject {
    var yieldModuleState: AnyPublisher<YieldModuleManagerStateInfo, Never> { get }
}
