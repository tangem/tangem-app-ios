//
//  ManageTokensSettingsFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct ManageTokensSettingsFactory {
    func make(from userWalletModel: UserWalletModel?) -> ManageTokensSettings {
        guard let userWalletModel = userWalletModel else {
            return empty()
        }

        let shouldShowLegacyDerivationAlert = userWalletModel.config.warningEvents.contains(where: { $0 == .legacyDerivation })
        var supportedBlockchains = userWalletModel.config.supportedBlockchains
        supportedBlockchains.remove(.ducatus)

        let settings = ManageTokensSettings(
            supportedBlockchains: supportedBlockchains,
            hdWalletsSupported: userWalletModel.config.hasFeature(.hdWallets),
            longHashesSupported: userWalletModel.config.hasFeature(.longHashes),
            derivationStyle: userWalletModel.config.derivationStyle,
            shouldShowLegacyDerivationAlert: shouldShowLegacyDerivationAlert,
            existingCurves: (userWalletModel as? CardViewModel)?.card.walletCurves ?? []
        )

        return settings
    }

    private func empty() -> ManageTokensSettings {
        .init(
            supportedBlockchains: [],
            hdWalletsSupported: false,
            longHashesSupported: false,
            derivationStyle: nil,
            shouldShowLegacyDerivationAlert: false,
            existingCurves: []
        )
    }
}
