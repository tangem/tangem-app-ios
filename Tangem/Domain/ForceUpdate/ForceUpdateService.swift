//
//  ForceUpdateService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

protocol ForceUpdateService: AnyObject {
    var state: ForceUpdateState { get }
    var statePublisher: AnyPublisher<ForceUpdateState, Never> { get }

    func checkForUpdates()
}

private struct ForceUpdateServiceKey: InjectionKey {
    static var currentValue: ForceUpdateService = CommonForceUpdateService()
}

extension InjectedValues {
    var forceUpdateService: ForceUpdateService {
        get { Self[ForceUpdateServiceKey.self] }
        set { Self[ForceUpdateServiceKey.self] = newValue }
    }
}
