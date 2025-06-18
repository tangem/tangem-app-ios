//
//  UserWalletEncryptionKeyFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

class UserWalletEncryptionKeyFactory {
    func encryptionKey(for userWallet: StoredUserWallet) -> UserWalletEncryptionKey? {
        let walletInfo = userWallet.info()
        let config = UserWalletConfigFactory().makeConfig(walletInfo: walletInfo)

        guard let userWalletIdSeed = config.userWalletIdSeed else { return nil }

        return UserWalletEncryptionKey(userWalletIdSeed: userWalletIdSeed)
    }
}
