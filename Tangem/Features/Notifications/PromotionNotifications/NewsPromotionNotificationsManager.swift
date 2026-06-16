//
//  NewsPromotionNotificationsManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt
import TangemFoundation

final class NewsPromotionNotificationsManager {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    private let cache = Cache()

    private var selectedUserWalletId: UserWalletId? {
        userWalletRepository.selectedModel?.userWalletId
    }

    private var selectedUserWalletIdPublisher: AnyPublisher<UserWalletId, Never> {
        userWalletRepository.eventProvider
            .compactMap { event in
                guard case .selected(let userWalletId) = event else {
                    return nil
                }

                return userWalletId
            }
            .prepend(selectedUserWalletId)
            .compactMap(\.self)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    private func manager(for userWalletId: UserWalletId) async -> PromotionNotificationsManager {
        await cache.manager(for: userWalletId)
    }
}

// MARK: - PromotionNotificationsManager

extension NewsPromotionNotificationsManager: PromotionNotificationsManager {
    var notificationInputs: [NotificationViewInput] {
        get async {
            guard let userWalletId = selectedUserWalletId else {
                return []
            }

            return await manager(for: userWalletId).notificationInputs
        }
    }

    var notificationPublisher: AnyPublisher<[NotificationViewInput], Never> {
        selectedUserWalletIdPublisher
            .withWeakCaptureOf(self)
            .asyncMap { wrapper, userWalletId in
                await wrapper.manager(for: userWalletId).notificationPublisher
            }
            .switchToLatest()
            .eraseToAnyPublisher()
    }

    func setupManager(with delegate: NotificationTapDelegate?) {
        assertionFailure("Handles deeplinks internally, no external delegate needed")
    }

    func dismissNotification(with id: NotificationViewId) {
        guard let userWalletId = selectedUserWalletId else {
            return
        }

        runTask(in: self) { manager in
            await manager.manager(for: userWalletId).dismissNotification(with: id)
        }
    }

    func loadPromotions() async {
        guard let userWalletId = selectedUserWalletId else {
            return
        }

        await manager(for: userWalletId).loadPromotions()
    }
}

// MARK: - Auxiliary types

private extension NewsPromotionNotificationsManager {
    actor Cache {
        private var managers: [UserWalletId: PromotionNotificationsManager] = [:]

        func manager(for userWalletId: UserWalletId) -> PromotionNotificationsManager {
            if let cached = managers[userWalletId] {
                return cached
            }

            let newManager = CommonPromotionNotificationsManager(userWalletId: userWalletId, placement: .news)
            managers[userWalletId] = newManager

            return newManager
        }
    }
}
