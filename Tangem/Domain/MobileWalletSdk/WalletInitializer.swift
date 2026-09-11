//
//  WalletInitializer.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import TangemMobileWalletSdk
import BlockchainSdk

protocol WalletInitializer {
    associatedtype Wallet

    func initializeWallet(parameters: WalletInitializerParameters) async throws -> Wallet
}

struct WalletInitializerParameters {
    let mnemonic: Mnemonic?
    let passphrase: String?
    /// Whether the user already holds the recovery phrase of the wallet being initialized.
    let hasMnemonicBackup: Bool
    /// Whether a backup of the wallet being initialized already exists in iCloud.
    let hasICloudBackup: Bool
}

final class MobileWalletInitializer: WalletInitializer {
    typealias Wallet = MobileWalletInfo

    func initializeWallet(parameters: WalletInitializerParameters) async throws -> MobileWalletInfo {
        let sdk = CommonMobileWalletSdk()

        let userWalletId = switch parameters.mnemonic {
        case .some(let mnemonic):
            try sdk.importWallet(entropy: mnemonic.getEntropy(), passphrase: parameters.passphrase ?? "")
        case .none:
            try sdk.generateWallet()
        }

        let context = try sdk.validate(auth: .none, for: userWalletId)

        let mobileWallet = try sdk.deriveMasterKeys(context: context)

        let publicKeys: [EllipticCurve: Data] = mobileWallet.wallets.reduce(into: [:]) { result, key in
            result[key.curve] = key.publicKey
        }

        var mobileWalletInfo = MobileWalletInfo(
            hasMnemonicBackup: parameters.hasMnemonicBackup,
            hasICloudBackup: parameters.hasICloudBackup,
            accessCodeStatus: .none,
            keys: []
        )

        let config = MobileUserWalletConfig(mobileWalletInfo: mobileWalletInfo)

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
                    isImported: parameters.mnemonic != nil,
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
