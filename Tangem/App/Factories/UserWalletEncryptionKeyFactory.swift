//
//  UserWalletEncryptionKeyFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

class UserWalletEncryptionKeyFactory {
    #warning("[REDACTED_TODO_COMMENT]")

    func encryptionKey(from cardInfo: CardInfo) -> UserWalletEncryptionKey? {
        let config = UserWalletConfigFactory(cardInfo).makeConfig()

        guard let seed = config.userWalletIdSeed else { return nil }

        return encryptionKey(from: seed)
    }

    func encryptionKey(from userWalletIdSeed: Data) -> UserWalletEncryptionKey {
        return UserWalletEncryptionKey(with: userWalletIdSeed)
    }
}
