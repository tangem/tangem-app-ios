//
//  PushNotificationsInteractorMock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

class PushNotificationsInteractorMock: PushNotificationsInteractor {
    func isAvailable(in flow: PushNotificationsPermissionRequestFlow) -> Bool {
        true
    }

    func allowRequest(in flow: PushNotificationsPermissionRequestFlow) async {}

    func postponeRequest(in flow: PushNotificationsPermissionRequestFlow) {}

    func initialize() {}

    func registerForPushNotifications(completion: @escaping (Result<Void, Error>) -> Void) {
        completion(.success(()))
    }
}
