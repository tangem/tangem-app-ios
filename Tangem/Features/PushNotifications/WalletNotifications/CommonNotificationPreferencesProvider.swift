//
//  CommonNotificationPreferencesProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

final class CommonNotificationPreferencesProvider {
    // MARK: - Dependencies

    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    // MARK: - Private Properties

    private let userWalletId: String
    private var updateTask: Task<Void, Never>?

    // MARK: - Init

    init(userWalletId: String) {
        self.userWalletId = userWalletId
    }
}

// MARK: - NotificationPreferencesDTO.Body

private extension NotificationPreferencesDTO.Body {
    init(_ settings: [(type: PushNotificationsSettingType, isEnabled: Bool)]) {
        let map = Dictionary(uniqueKeysWithValues: settings.map { ($0.type, $0.isEnabled) })
        transactionAlerts = map[.transactionAlerts] ?? false
        offersUpdates = map[.offersUpdates] ?? false
        priceAlerts = map[.priceAlerts] ?? false
    }
}

// MARK: - NotificationPreferencesProvider

extension CommonNotificationPreferencesProvider: NotificationPreferencesProvider {
    func updatePreferences(_ preferences: [(type: PushNotificationsSettingType, isEnabled: Bool)]) throws {
        let requestBody = NotificationPreferencesDTO.Body(preferences)
        updateTask?.cancel()
        updateTask = runTask(in: self) { provider in
            do {
                try await provider.tangemApiService.updateNotificationPreferences(
                    userWalletId: provider.userWalletId,
                    preferences: requestBody
                )
            } catch {
                // Do nothing.
            }
        }
    }
}
