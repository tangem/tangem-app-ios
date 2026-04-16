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

    func compoundTransactionIfNeeded() throws -> (amount: BSDKAmount, destination: String)? {
        guard let balance = wallet.amounts[.coin] else {
            throw DynamicAddressesWalletUpdaterError.balanceNotFound
        }

        let plainWallet = try makePlainWallet()
        let plainWalletDefaultAddress = plainWallet.address

        let addressesWithBalance = wallet.addressesBalances
            .filter { $0.value.value > 0 }
            .map(\.key)
            .toSet()

        let plainWalletAddresses = plainWallet.addresses.map(\.value)
        let hasMoreThanDefaultAddressWithBalance = !addressesWithBalance.subtracting(plainWalletAddresses).isEmpty

        guard hasMoreThanDefaultAddressWithBalance, balance.value > 0 else {
            return nil
        }

        return (amount: balance, destination: plainWalletDefaultAddress)
    }

    func updateToXPUBKey(xpubKey: Wallet.PublicKey.XPUBKey) throws {
        let newWallet = try makeXpubWallet(xpubKey: xpubKey)
        try walletUpdater.update(wallet: newWallet)
    }

    func updateToPlainKey() throws {
        let newWallet = try makePlainWallet()
        try walletUpdater.update(wallet: newWallet)
    }
}

// MARK: - Private

private extension DynamicAddressesWalletUpdater {
    func makeXpubWallet(xpubKey: Wallet.PublicKey.XPUBKey) throws -> Wallet {
        guard case .plain(let plainKey) = wallet.publicKey.derivationType else {
            throw DynamicAddressesWalletUpdaterError.plainHDKeyNotFound
        }

        return try makeWallet(derivationType: .xpub(plain: plainKey, xpub: xpubKey))
    }

    func makePlainWallet() throws -> Wallet {
        guard case .xpub(let plainKey, _) = wallet.publicKey.derivationType else {
            throw DynamicAddressesWalletUpdaterError.xpubHDKeyNotFound
        }

        return try makeWallet(derivationType: .plain(plainKey))
    }

    func makeWallet(derivationType: Wallet.PublicKey.DerivationType) throws -> Wallet {
        let publicKey = Wallet.PublicKey(
            seedKey: wallet.publicKey.seedKey,
            derivationType: derivationType
        )
        let factory = WalletFactory(blockchain: wallet.blockchain)
        let wallet = try factory.makeWallet(publicKey: publicKey)
        return wallet
    }
}

enum DynamicAddressesWalletUpdaterError: LocalizedError {
    case balanceNotFound
    case plainHDKeyNotFound
    case xpubHDKeyNotFound

    var errorDescription: String? {
        switch self {
        case .balanceNotFound: "Balance not found."
        case .plainHDKeyNotFound: "Plain HD key not found."
        case .xpubHDKeyNotFound: "XPUB HD key not found."
        }
    }
}
