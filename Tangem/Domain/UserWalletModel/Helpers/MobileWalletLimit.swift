//
//  MobileWalletLimit.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum MobileWalletLimit {
    static let maxCount = 5

    static func isReached(in userWalletModels: [UserWalletModel]) -> Bool {
        mobileWallets(in: userWalletModels).count >= maxCount
    }

    static func isReached(for userWalletModel: UserWalletModel, in userWalletModels: [UserWalletModel]) -> Bool {
        isMobileWallet(userWalletModel) && isReached(in: userWalletModels)
    }

    static func mobileWallets(in userWalletModels: [UserWalletModel]) -> [UserWalletModel] {
        userWalletModels.filter(isMobileWallet)
    }
}

// MARK: - Private methods

private extension MobileWalletLimit {
    static func isMobileWallet(_ userWalletModel: UserWalletModel) -> Bool {
        !userWalletModel.config.hasFeature(.nfcInteraction)
    }
}
