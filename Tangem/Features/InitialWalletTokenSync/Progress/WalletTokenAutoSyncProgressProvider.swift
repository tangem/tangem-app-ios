//
//  WalletTokenAutoSyncProgressProvider.swift
//  Tangem
//
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation

// MARK: - WalletTokenAutoSyncProgressProvider

protocol WalletTokenAutoSyncProgressProvider {
    func progressPublisher(for userWalletId: UserWalletId) async -> AnyPublisher<Int, Never>?
    func eventPublisher(for userWalletId: UserWalletId) async -> AnyPublisher<WalletTokenAutoSyncProgressEvent, Never>
    func removeProgress(for userWalletId: UserWalletId) async
}
