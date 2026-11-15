//
//  CommonUserWalletConfigProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

final class CommonUserWalletConfigProvider {
    private let initialConfig: UserWalletConfig
    private weak var userWalletModel: (any UserWalletModel)?

    init(config: UserWalletConfig) {
        initialConfig = config
    }

    func configure(userWalletModel: UserWalletModel) {
        self.userWalletModel = userWalletModel
    }
}

// MARK: - UserWalletConfigProvider

extension CommonUserWalletConfigProvider: UserWalletConfigProvider {
    var config: UserWalletConfig {
        userWalletModel?.config ?? initialConfig
    }
}
