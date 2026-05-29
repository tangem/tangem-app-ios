//
//  AppUpdateService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

protocol AppUpdateService: AnyObject {
    var state: AppUpdateState { get }
    var statePublisher: AnyPublisher<AppUpdateState, Never> { get }

    func checkForUpdates()
}

private struct AppUpdateServiceKey: InjectionKey {
    static var currentValue: AppUpdateService = CommonAppUpdateService()
}

extension InjectedValues {
    var appUpdateService: AppUpdateService {
        get { Self[AppUpdateServiceKey.self] }
        set { Self[AppUpdateServiceKey.self] = newValue }
    }
}
