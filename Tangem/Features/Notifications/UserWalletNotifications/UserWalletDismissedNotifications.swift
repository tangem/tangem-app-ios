//
//  UserWalletDismissedNotifications.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

protocol UserWalletDismissedNotifications {
    func add(userWalletId: UserWalletId, notification: UserWalletDismissedNotification)
    func has(userWalletId: UserWalletId, notification: UserWalletDismissedNotification) -> Bool
}

enum UserWalletDismissedNotification {
    case mobileUpgradeFromMain
    case mobileUpgradeFromSettings
}

final class CommonUserWalletDismissedNotifications {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    private var items: [Item] = []
    private var bag: Set<AnyCancellable> = []

    fileprivate init() {
        bind()
    }
}

// MARK: - Private methods

private extension CommonUserWalletDismissedNotifications {
    func bind() {
        userWalletRepository.eventProvider
            .withWeakCaptureOf(self)
            .sink { manager, event in
                manager.handleUserWalletRepositoryEvent(event)
            }
            .store(in: &bag)
    }

    func handleUserWalletRepositoryEvent(_ event: UserWalletRepositoryEvent) {
        switch event {
        case .unlocked:
            userWalletRepository.models
                .filter { !$0.isUserWalletLocked }
                .map(\.userWalletId)
                .forEach {
                    clean(userWalletId: $0)
                }

        case .unlockedWallet(let userWalletId):
            clean(userWalletId: userWalletId)

        case .deleted(let userWalletIds, _):
            userWalletIds.forEach {
                clean(userWalletId: $0)
            }

        default:
            break
        }
    }

    func clean(userWalletId: UserWalletId) {
        items.removeAll(where: { $0.id == userWalletId })
    }
}

// MARK: - UserWalletDismissedNotifications

extension CommonUserWalletDismissedNotifications: UserWalletDismissedNotifications {
    func add(userWalletId: UserWalletId, notification: UserWalletDismissedNotification) {
        let item = Item(id: userWalletId, notification: notification)
        guard !items.contains(where: { $0 == item }) else {
            return
        }
        items.append(item)
    }

    func has(userWalletId: UserWalletId, notification: UserWalletDismissedNotification) -> Bool {
        let item = Item(id: userWalletId, notification: notification)
        return items.contains(where: { $0 == item })
    }
}

// MARK: - Types

private extension CommonUserWalletDismissedNotifications {
    struct Item: Equatable {
        let id: UserWalletId
        let notification: UserWalletDismissedNotification
    }
}

// MARK: - Injection

private struct UserWalletDismissedNotificationsKey: InjectionKey {
    static var currentValue: UserWalletDismissedNotifications = CommonUserWalletDismissedNotifications()
}

extension InjectedValues {
    var userWalletDismissedNotifications: UserWalletDismissedNotifications {
        get { Self[UserWalletDismissedNotificationsKey.self] }
        set { Self[UserWalletDismissedNotificationsKey.self] = newValue }
    }
}
