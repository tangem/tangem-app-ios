//
//  CustomerIOWrapper.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import CioDataPipelines
import CioMessagingPushFCM
import TangemFoundation

final class CustomerIOWrapper {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    private var userWalletRepositoryEventCancellable: AnyCancellable?
    private var fcmTokenUpdatedCancellable: AnyCancellable?

    func configure() {
        // [REDACTED_USERNAME], this mimics current Firebase - dependent behavior of the app.
        // See ``CommonServicesManager.configureFirebase``.
        guard !AppEnvironment.current.isDebug else {
            return
        }

        guard let cdpApiKey = CustomerIOConfigProvider.cdpApiKey, !cdpApiKey.isEmpty else {
            return
        }

        let sdkConfig = SDKConfigBuilder(cdpApiKey: cdpApiKey)
            .tangemDataPipelineDefaults()
            .build()

        let pushConfig = MessagingPushConfigBuilder()
            .tangemPushDefaults()
            .build()

        CustomerIO.initialize(withConfig: sdkConfig)
        MessagingPush.initialize(withConfig: pushConfig)

        subscribeToUserWalletRepositoryEvents()
        subscribeToFcmTokenUpdatedEvent()
    }

    private func subscribeToUserWalletRepositoryEvents() {
        userWalletRepositoryEventCancellable = userWalletRepository
            .eventProvider
            .removeDuplicates()
            .sink { event in
                switch event {
                case .selected(let userWalletId):
                    let userId = userWalletId.hashedStringValue
                    CustomerIO.shared.identify(userId: userId)
                    AppLogger.info("Customer.io user identity updated with selected user wallet id.")
                case .deleted(_, isRepositoryEmpty: true):
                    CustomerIO.shared.clearIdentify()
                    AppLogger.info("Customer.io identity cleared after the last user wallet was removed.")
                default:
                    break
                }
            }
    }

    private func subscribeToFcmTokenUpdatedEvent() {
        fcmTokenUpdatedCancellable = AppSettings.shared
            .$lastStoredFCMToken
            .removeDuplicates()
            .compactMap(\.self)
            .filter(\.isNotEmpty)
            .sink { fcmToken in
                MessagingPush.shared.registerDeviceToken(fcmToken: fcmToken)
                AppLogger.info("Customer.io device token registered.")
            }
    }
}
