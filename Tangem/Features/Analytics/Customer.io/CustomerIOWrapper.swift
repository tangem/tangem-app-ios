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
    @Injected(\.keysManager) private var keysManager: any KeysManager
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    private var userWalletSelectedCancellable: AnyCancellable?
    private var fcmTokenUpdatedCancellable: AnyCancellable?

    func configure() {
        let sdkConfig = SDKConfigBuilder(cdpApiKey: keysManager.customerIO.apiKey)
            .autoTrackUIKitScreenViews(enabled: false)
            .autoTrackDeviceAttributes(false)
            .trackApplicationLifecycleEvents(false)
            .logLevel(.error)
            .build()

        let pushConfig = MessagingPushConfigBuilder()
            .autoFetchDeviceToken(false)
            .autoTrackPushEvents(true)
            .build()

        CustomerIO.initialize(withConfig: sdkConfig)
        MessagingPush.initialize(withConfig: pushConfig)

        subscribeToSelectedUserWalletEvent()
        subscribeToFcmTokenUpdatedEvent()
    }

    private func subscribeToSelectedUserWalletEvent() {
        userWalletSelectedCancellable = userWalletRepository
            .eventProvider
            .removeDuplicates()
            .sink { event in
                guard case .selected(let userWalletId) = event else {
                    return
                }

                let userId = userWalletId.hashedStringValue
                CustomerIO.shared.identify(userId: userId)
                AppLogger.info("Customer.io user identity updated with selected user wallet id.")
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
