//
//  PushNotificationsSyncApplicationsProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

/// Provides remote "application" registration and FCM token updates for user-wallet push notifications.
final class PushNotificationsSyncApplicationsProvider {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    enum InitializeType {
        case create
        case update
    }

    func initializeType(applicationUid: String) -> InitializeType {
        applicationUid.isEmpty ? .create : .update
    }

    func createApplication(fcmToken: String) async throws {
        let deviceInfo = DeviceInfo()

        let requestModel = ApplicationDTO.Request(
            pushToken: fcmToken,
            platform: deviceInfo.platform,
            device: deviceInfo.device,
            systemVersion: deviceInfo.systemVersion,
            language: deviceInfo.appLanguageCode,
            timezone: deviceInfo.timezone,
            version: deviceInfo.version,
            appsflyerId: AppsFlyerWrapper.shared.appsflyerId
        )

        let response = try await tangemApiService.createUserWalletsApplications(requestModel: requestModel)

        await MainActor.run {
            AppSettings.shared.applicationUid = response.uid
            AppSettings.shared.lastStoredFCMToken = fcmToken
        }
    }

    func updateApplication(fcmToken: String?, applicationUid: String) async throws {
        let requestModel = ApplicationDTO.Update.Request(pushToken: fcmToken)
        try await tangemApiService.updateUserWalletsApplications(uid: applicationUid, requestModel: requestModel)

        await MainActor.run {
            AppSettings.shared.lastStoredFCMToken = fcmToken
        }
    }
}
