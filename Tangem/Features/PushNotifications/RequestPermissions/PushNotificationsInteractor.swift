//
//  PushNotificationsInteractor.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol PushNotificationsInteractor: Initializable {
    func isAvailable(in flow: PushNotificationsPermissionRequestFlow) -> Bool
    func allowRequest(in flow: PushNotificationsPermissionRequestFlow) async
    func postponeRequest(in flow: PushNotificationsPermissionRequestFlow)
}

// MARK: - Dependency injection

extension InjectedValues {
    var pushNotificationsInteractor: PushNotificationsInteractor {
        get { Self[Key.self] }
        set { Self[Key.self] = newValue }
    }

    private struct Key: InjectionKey {
        static var currentValue: PushNotificationsInteractor = CommonPushNotificationsInteractor()
    }
}
