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

    /// Has to be computed because `Wallet` is struct and can be replaced
    var wallet: Wallet { walletProvider.wallet }

    func compoundTransactionIfNeeded() -> (amount: BSDKAmount, destination: String)? {
        guard let balance = wallet.amounts[.coin], balance.value > 0 else {
            return nil
        }

        let hasUsedAddresses = wallet.addresses.contains(where: { $0.type.isUsed() })
        guard hasUsedAddresses else {
            return nil
        }

        let destination = wallet.defaultAddress.value

        return (amount: balance, destination: destination)
    }

    func updateToXPUBKey(xpubKey: Wallet.PublicKey.XPUBKey) throws {
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
