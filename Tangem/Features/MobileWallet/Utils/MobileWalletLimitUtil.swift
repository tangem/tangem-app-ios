//
//  MobileWalletLimitUtil.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct MobileWalletLimitUtil {
    @Injected(\.userWalletRepository)
    private var userWalletRepository: UserWalletRepository

    private var hasSocialWallet: Bool {
        MobileWalletLimit.mobileWallets(in: userWalletRepository.models).contains { $0.config.hasSocialLogin }
    }
}

// MARK: - Internal methods

extension MobileWalletLimitUtil {
    func restriction(for addition: Addition) -> Restriction? {
        if userWalletRepository.isMobileWalletsLimitReached {
            return .mobileWalletsLimitReached(addition)
        }

        if addition == .socialLogin, hasSocialWallet {
            return .socialWalletAlreadyAdded
        }

        return nil
    }
}

// MARK: - Types

extension MobileWalletLimitUtil {
    enum Addition {
        case create
        case `import`
        case socialLogin
    }
}
