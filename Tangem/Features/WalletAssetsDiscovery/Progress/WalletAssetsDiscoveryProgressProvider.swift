//
//  WalletAssetsDiscoveryProgressProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation

// MARK: - WalletAssetsDiscoveryProgressProvider

protocol WalletAssetsDiscoveryProgressProvider {
    func progressPublisher(for userWalletId: UserWalletId) async -> AnyPublisher<Int, Never>?
    func eventPublisher(for userWalletId: UserWalletId) async -> AnyPublisher<WalletAssetsDiscoveryProgressEvent, Never>
    func removeProgress(for userWalletId: UserWalletId) async
}
