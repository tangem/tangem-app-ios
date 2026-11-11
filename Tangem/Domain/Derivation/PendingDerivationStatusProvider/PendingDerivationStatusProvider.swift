//
//  PendingDerivationStatusProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

protocol PendingDerivationStatusProvider: AnyObject {
    var hasPendingDerivations: AnyPublisher<Bool, Never> { get }
    var pendingDerivationsCount: AnyPublisher<Int, Never> { get }
}

// MARK: - Default implementation

extension PendingDerivationStatusProvider where Self: AccountPendingDerivationProvider {
    var hasPendingDerivations: AnyPublisher<Bool, Never> {
        pendingDerivationsPublisher
            .map { !$0.isEmpty }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    var pendingDerivationsCount: AnyPublisher<Int, Never> {
        pendingDerivationsPublisher
            .map { pending in
                // In some rare edge cases (old wallets, etc) there might be multiple master keys with the same curve.
                // All such master keys have the same set of pending derivations, so we need to select only master keys
                // distinct by `network` to avoid counting the same pending derivations but for different master keys multiple times.
                pending.unique(by: \.network).count
            }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}
