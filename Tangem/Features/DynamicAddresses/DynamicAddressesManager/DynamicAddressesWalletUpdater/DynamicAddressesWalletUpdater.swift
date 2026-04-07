//
//  DynamicAddressesWalletUpdater.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct DynamicAddressesWalletUpdater {
    let walletProvider: WalletProvider
    let walletUpdater: WalletReplaceable

    func updateToXPUBKey(xpubKey: Wallet.PublicKey.XPUBKey) throws {
        let wallet = walletProvider.wallet

        guard case .plain(let plainKey) = wallet.publicKey.derivationType else {
            throw DynamicAddressesWalletUpdaterError.plainHDKeyNotFound
        }

        let xpubPublicKey = Wallet.PublicKey(
            seedKey: wallet.publicKey.seedKey,
            derivationType: .xpub(plain: plainKey, xpub: xpubKey)
        )
        let factory = WalletFactory(blockchain: wallet.blockchain)
        let newWallet = try factory.makeWallet(publicKey: xpubPublicKey)
        try walletUpdater.update(wallet: newWallet)
    }

    func updateToPlainKey() throws {
        let wallet = walletProvider.wallet

        guard case .xpub(let plainKey, _) = wallet.publicKey.derivationType else {
            throw DynamicAddressesWalletUpdaterError.xpubHDKeyNotFound
        }

        let plainPublicKey = Wallet.PublicKey(
            seedKey: wallet.publicKey.seedKey,
            derivationType: .plain(plainKey)
        )
        let factory = WalletFactory(blockchain: wallet.blockchain)
        let newWallet = try factory.makeWallet(publicKey: plainPublicKey)
        try walletUpdater.update(wallet: newWallet)
    }
}

enum DynamicAddressesWalletUpdaterError: LocalizedError {
    case plainHDKeyNotFound
    case xpubHDKeyNotFound
}
