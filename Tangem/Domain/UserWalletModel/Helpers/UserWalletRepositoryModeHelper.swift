//
//  UserWalletRepositoryModeHelper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum UserWalletRepositoryModeHelper {
    @Injected(\.userWalletRepository) private static var userWalletRepository: UserWalletRepository

    static var hasSingleMobileWallet: Bool {
        userWalletRepository.models.count == 1 && mode == .mobile
    }

    static var mode: UserWalletRepositoryMode {
        if userWalletRepository.models.isEmpty {
            return .empty
        }

        let hasNFC = userWalletRepository.models.map {
            $0.config.hasFeature(.nfcInteraction)
        }

        if hasNFC.allSatisfy({ $0 }) {
            return .hardware
        }

        if hasNFC.allSatisfy({ !$0 }) {
            return .mobile
        }

        return .mixed
    }
}
