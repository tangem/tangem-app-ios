//
//  WalletInitializer.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import TangemHotSdk
import BlockchainSdk

protocol WalletInitializer {
    associatedtype Wallet

    func initializeWallet(mnemonic: Mnemonic?, passphrase: String?) async throws -> Wallet
}

final class MobileWalletInitializer: WalletInitializer {
    typealias Wallet = HotWalletInfo

    func initializeWallet(mnemonic: Mnemonic?, passphrase: String?) async throws -> HotWalletInfo {
        let sdk = CommonHotSdk()

        let userWalletId = switch mnemonic {
        case .some(let mnemonic):
            try sdk.importWallet(entropy: mnemonic.getEntropy(), passphrase: passphrase ?? "")
        case .none:
            try sdk.generateWallet()
        }

        let context = try sdk.validate(auth: .none, for: userWalletId)

        let mobileWallet = try sdk.deriveMasterKeys(context: context)

        let publicKeys: [EllipticCurve: Data] = mobileWallet.wallets.reduce(into: [:]) { result, key in
            result[key.curve] = key.publicKey
        }

        var mobileWalletInfo = HotWalletInfo(
            hasMnemonicBackup: mnemonic != nil,
            hasICloudBackup: false,
            isAccessCodeSet: false,
            keys: []
        )

        let config = HotUserWalletConfig(hotWalletInfo: mobileWalletInfo)

        let derivationPaths: [Data: [DerivationPath]] = config.supportedBlockchains.reduce(
            into: [:]
        ) { result, blockchain in
            guard let publicKey = publicKeys[blockchain.curve] else {
                return
            }

            let blockchainNetwork = self.blockchainNetwork(from: blockchain, config: config)
            result[publicKey, default: []] += blockchainNetwork.derivationPaths()
        }

        let derivationResult = try sdk.deriveKeys(context: context, derivationPaths: derivationPaths)

        let keyInfos: [KeyInfo] = mobileWallet.wallets.reduce(into: []) { keyInfos, wallet in
            guard let derivedKeys = derivationResult[wallet.publicKey] else {
                return
            }

            keyInfos.append(
                KeyInfo(
                    publicKey: wallet.publicKey,
                    chainCode: wallet.chainCode,
                    curve: wallet.curve,
                    isImported: mnemonic != nil,
                    derivedKeys: derivedKeys.derivedKeys
                )
            )
        }

        mobileWalletInfo.keys = keyInfos

        return mobileWalletInfo
    }

    private func blockchainNetwork(from blockchain: Blockchain, config: UserWalletConfig) -> BlockchainNetwork {
        switch config.derivationStyle {
        case .some(let style):
            let derivationPath = blockchain.derivationPath(for: style)
            return BlockchainNetwork(blockchain, derivationPath: derivationPath)
        case .none:
            return BlockchainNetwork(blockchain, derivationPath: nil)
        }
    }
}
