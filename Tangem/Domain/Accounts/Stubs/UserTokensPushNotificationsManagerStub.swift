//
//  UserTokensPushNotificationsManagerStub.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

@available(iOS, deprecated: 100000.0, message: "Temporary stub until accounts support is added ([REDACTED_INFO])")
final class UserTokensPushNotificationsManagerStub: UserTokensPushNotificationsManager, UserTokenListExternalParametersProvider {
    private let statusSubject = CurrentValueSubject<UserWalletPushNotifyStatus, Never>(
        .unavailable(reason: .notInitialized, enabledRemote: false)
    )

    var statusPublisher: AnyPublisher<UserWalletPushNotifyStatus, Never> {
        statusSubject.eraseToAnyPublisher()
    }

    var status: UserWalletPushNotifyStatus {
        statusSubject.value
    }

    func handleUpdateWalletPushNotifyStatus(_ status: UserWalletPushNotifyStatus) {}

    func provideTokenListAddresses() -> [WalletModelId: [String]]? { nil }

    func provideTokenListNotifyStatusValue() -> Bool {
        false
    }
}
