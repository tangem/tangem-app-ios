//
//  VisaWalletManagerFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk
import TangemVisa

struct VisaWalletManagerFactory: AnyWalletManagerFactory {
    func makeWalletManager(blockchainNetwork: BlockchainNetwork, tokens: [Token], keys: [KeyInfo], apiList: APIList) throws -> WalletManager {
        let visaBlockchainNetwork = BlockchainNetwork(VisaUtilities.visaBlockchain, derivationPath: blockchainNetwork.derivationPath)
        let publicKey = try SimpleWalletPublicKeyFactory().makePublicKey(blockchainNetwork: visaBlockchainNetwork, keys: keys)

        let factory = WalletManagerFactoryProvider(apiList: apiList).factory
        let walletManager = try factory.makeWalletManager(blockchain: VisaUtilities.visaBlockchain, publicKey: publicKey)

        return walletManager
    }
}
