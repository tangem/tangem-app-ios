//
//  JointAccountsNotificationBadgeCounter.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import CombineExt
import TangemFoundation

struct JointAccountsNotificationBadgeCounter {
    private let accountModelsManager: AccountModelsManager

    init(accountModelsManager: AccountModelsManager) {
        self.accountModelsManager = accountModelsManager
    }
}

// MARK: - NotificationBadgeCounter protocol conformance

extension JointAccountsNotificationBadgeCounter: NotificationBadgeCounter {
    var notificationBadgeCountPublisher: AnyPublisher<Int, Never> {
        AccountModelsAggregator(.joint)
            .modelsPublisher(from: accountModelsManager)
            .flatMapLatest { jointAccounts -> AnyPublisher<Int, Never> in
                guard jointAccounts.isNotEmpty else {
                    return .just(output: 0)
                }

                return jointAccounts
                    .map(awaitingOwnSignatureCountPublisher(for:))
                    .combineLatest()
                    .map { $0.reduce(0, +) }
                    .eraseToAnyPublisher()
            }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}

// MARK: - CustomStringConvertible protocol conformance

extension JointAccountsNotificationBadgeCounter: CustomStringConvertible {
    var description: String { "JointAccounts" }
}

// MARK: - Private

private extension JointAccountsNotificationBadgeCounter {
    func awaitingOwnSignatureCountPublisher(for jointAccount: any JointAccountModel) -> AnyPublisher<Int, Never> {
        jointAccount
            .jointAccountPendingOperationsProvider
            .pendingOperationsPublisher
            .combineLatest(jointAccount.jointAccountMembersService.slotsPublisher.map(\.members))
            .map { operations, members in
                guard members.contains(where: \.isMe) else {
                    return 0
                }

                return operations.filter(\.canSign).count
            }
            .eraseToAnyPublisher()
    }
}
