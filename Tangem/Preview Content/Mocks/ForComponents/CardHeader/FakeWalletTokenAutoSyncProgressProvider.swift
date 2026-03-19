//
//  FakeWalletTokenAutoSyncProgressProvider.swift
//  Tangem
//
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation

struct FakeWalletTokenAutoSyncProgressProvider: WalletTokenAutoSyncProgressProvider {
    private let percent: Int?

    var eventPipeline: AnyPublisher<[UserWalletId: WalletTokenAutoSyncProgressEvent], Never> {
        Empty().eraseToAnyPublisher()
    }

    init(percent: Int? = nil) {
        self.percent = percent
    }

    func progressPublisher(for userWalletId: UserWalletId) async -> AnyPublisher<Int, Never>? {
        guard let percent else {
            return nil
        }
        return Just(percent).eraseToAnyPublisher()
    }

    func eventPublisher(for userWalletId: UserWalletId) async -> AnyPublisher<WalletTokenAutoSyncProgressEvent, Never> {
        Just(.inProgress(percent: percent ?? 0)).eraseToAnyPublisher()
    }
}
