//
//  TangemPayAccountManagingMock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class TangemPayAccountManagingMock: TangemPayAccountManaging {
    var statePublisher: AnyPublisher<TangemPayAccountManagingState, Never> { .empty }

    var notificationManager: TangemPayNotificationManager = .init()

    var tangemPayAccount: TangemPayAccount? = nil

    var tangemPayAccountPublisher: AnyPublisher<TangemPayAccount, Never> {
        .empty
    }

    var tangemPaySyncInProgressPublisher: AnyPublisher<Bool, Never> { .empty }

    var tangemPayStatusPublisher: AnyPublisher<TangemPayStatus, Never> { .empty }

    var tangemPayAuthorizingInteractor: any TangemPayAuthorizing {
        TangemPayAuthorizingMock()
    }

    func onTangemPayOfferAccepted(_ onFinish: @escaping () -> Void) async throws {}
    func onTangemPaySync() {}

    func loadCustomerInfo() -> Task<Void, Never> {
        Task {}
    }

    func freeze(cardId: String) async throws {}
    func unfreeze(cardId: String) async throws {}
    func launchKYC() async throws {}
}
