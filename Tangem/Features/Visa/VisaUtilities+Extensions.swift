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

    /// Hardcoded USDC token on visa blockchain network (currently - Polygon)
    static var usdcTokenItem: TokenItem {
        TokenItem.token(
            Token(
                name: "USDC",
                symbol: "USDC",
                contractAddress: "0x3c499c542cef5e3811e1192ce70d8cc03d5c3359",
                decimalCount: 6,
                id: "usd-coin",
                metadata: .fungibleTokenMetadata
            ),
            BlockchainNetwork(
                VisaUtilities.visaBlockchain,
                derivationPath: VisaUtilities.visaDefaultDerivationPath
            )
        )
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

extension Collection where Element == any WalletModel {
    var visaWalletModel: (any WalletModel)? {
        first { $0.tokenItem.blockchain == VisaUtilities.visaBlockchain }
    }
}
