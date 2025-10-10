//
//  VisaUtilities+Extensions.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk
import TangemVisa

extension VisaUtilities {
    static var visaBlockchain: Blockchain {
        VisaUtilities.visaBlockchain(isTestnet: FeatureStorage.instance.isTestnet)
    }

    static func makeAddress(using list: [KeyInfo]) -> Address? {
        guard let wallet = list.first(where: { $0.curve == VisaUtilities.mandatoryCurve }) else {
            return nil
        }

        return try? VisaUtilities.makeAddress(
            walletPublicKey: wallet.publicKey,
            isTestnet: FeatureStorage.instance.isTestnet
        )
    }
}

extension UserWalletModel {
    var visaWalletModel: (any WalletModel)? {
        walletModelsManager.walletModels
            .first { $0.tokenItem.blockchain == VisaUtilities.visaBlockchain }
    }
}
