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

    static var mode: UserWalletRepositoryMode {
        userWalletRepository.models.allSatisfy { !$0.config.hasFeature(.nfcInteraction) } ? .mobile : .hardware
    }
}
