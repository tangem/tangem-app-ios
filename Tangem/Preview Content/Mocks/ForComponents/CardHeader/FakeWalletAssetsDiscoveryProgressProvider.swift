//
//  FakeWalletAssetsDiscoveryProgressProvider.swift
//  Tangem
//
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation

struct FakeWalletAssetsDiscoveryProgressProvider: WalletAssetsDiscoveryProgressProvider {
    private let percent: Int?

    init(percent: Int? = nil) {
        self.percent = percent
    }

    func progressPublisher(for userWalletId: UserWalletId) async -> AnyPublisher<Int, Never>? {
        guard let percent else {
            return nil
        }
        return Just(percent).eraseToAnyPublisher()
    }

    func eventPublisher(for userWalletId: UserWalletId) async -> AnyPublisher<WalletAssetsDiscoveryProgressEvent, Never> {
        Just(.inProgress(percent: percent ?? 0)).eraseToAnyPublisher()
    }

    func removeProgress(for userWalletId: UserWalletId) async {}
}
