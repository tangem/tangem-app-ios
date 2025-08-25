//
//  TwinWalletManagerFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk
import TangemFoundation

struct TwinWalletManagerFactory {
    private let pairPublicKey: Data

    init(pairPublicKey: Data) {
        self.pairPublicKey = pairPublicKey
    }
}

extension TwinWalletManagerFactory: AnyWalletManagerFactory {
    func makeWalletManager(for token: StorageEntry, keys: [KeyInfo], apiList: APIList) throws -> WalletManager {
        guard let walletPublicKey = keys.first?.publicKey else {
            throw CommonError.noData
        }

        let factory = WalletManagerFactoryProvider(apiList: apiList).factory
        let twinManager = try factory.makeTwinWalletManager(
            walletPublicKey: walletPublicKey,
            pairKey: pairPublicKey,
            isTestnet: AppEnvironment.current.isTestnet
        )

        return twinManager
    }
}
