//
//  MultiWalletModelsFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

struct MultiWalletModelsFactory {
    private let isHDWalletAllowed: Bool
    private let derivationStyle: DerivationStyle?

    init(isHDWalletAllowed: Bool, derivationStyle: DerivationStyle?) {
        self.isHDWalletAllowed = isHDWalletAllowed
        self.derivationStyle = derivationStyle
    }

    private func makeMultiWalletModels(
        walletPublicKeys: [EllipticCurve: Data],
        entry: StorageEntry
    ) throws -> [WalletModel] {
        guard let walletPublicKey = walletPublicKeys[entry.blockchainNetwork.blockchain.curve] else {
            throw CommonError.noData
        }

        let factory = WalletManagerFactoryProvider().factory
        let walletManager = try factory.makeWalletManager(
            blockchain: entry.blockchainNetwork.blockchain,
            walletPublicKey: walletPublicKey
        )

        walletManager.addTokens(entry.tokens)

        let mainCoinModel = WalletModel(walletManager: walletManager, amountType: .coin, isCustom: false)
        let tokenModels = entry.tokens.map {
            let amountType: Amount.AmountType = .token(value: $0)
            let isTokenCustom = $0.id == nil

            return WalletModel(walletManager: walletManager, amountType: amountType, isCustom: isTokenCustom)
        }

        return [mainCoinModel] + tokenModels
    }

    private func makeMultiWalletModels(
        seedKeys: [EllipticCurve: Data],
        entry: StorageEntry,
        derivedKeys: [EllipticCurve: [DerivationPath: ExtendedPublicKey]],
        derivationStyle: DerivationStyle?
    ) throws -> [WalletModel] {
        let curve = entry.blockchainNetwork.blockchain.curve

        guard let derivationPath = entry.blockchainNetwork.derivationPath else {
            throw WalletModelsFactoryError.entryHasNotDerivationPath
        }

        guard let seedKey = seedKeys[curve],
              let derivedWalletKeys = derivedKeys[curve],
              let derivedKey = derivedWalletKeys[derivationPath] else {
            throw WalletModelsFactoryError.noDerivation
        }

        let factory = WalletManagerFactoryProvider().factory

        let walletManager = try factory.makeWalletManager(
            blockchain: entry.blockchainNetwork.blockchain,
            seedKey: seedKey,
            derivedKey: derivedKey,
            derivation: .custom(derivationPath)
        )

        walletManager.addTokens(entry.tokens)

        let isMainCoinCustom = derivationStyle.map { !isDerivationDefault(blockchainNetwork: entry.blockchainNetwork, derivationStyle: $0) }
            ?? false

        let mainCoinModel = WalletModel(walletManager: walletManager, amountType: .coin, isCustom: isMainCoinCustom)

        let tokenModels = entry.tokens.map {
            let amountType: Amount.AmountType = .token(value: $0)
            let isTokenCustom = isMainCoinCustom || $0.id == nil

            return WalletModel(walletManager: walletManager, amountType: amountType, isCustom: isTokenCustom)
        }

        return [mainCoinModel] + tokenModels
    }

    private func isDerivationDefault(blockchainNetwork: BlockchainNetwork, derivationStyle: DerivationStyle) -> Bool {
        let defaultDerivation = blockchainNetwork.blockchain.derivationPath(for: derivationStyle)
        let currentDerivation = blockchainNetwork.derivationPath
        return currentDerivation == defaultDerivation
    }
}

extension MultiWalletModelsFactory: WalletModelsFactory {
    func makeWalletModels(for token: StorageEntry, keys: [CardDTO.Wallet]) throws -> [WalletModel] {
        let walletPublicKeys: [EllipticCurve: Data] = keys.reduce(into: [:]) { partialResult, cardWallet in
            partialResult[cardWallet.curve] = cardWallet.publicKey
        }

        if isHDWalletAllowed {
            let derivedKeys: [EllipticCurve: [DerivationPath: ExtendedPublicKey]] = keys.reduce(into: [:]) { partialResult, cardWallet in
                partialResult[cardWallet.curve] = cardWallet.derivedKeys
            }

            return try makeMultiWalletModels(
                seedKeys: walletPublicKeys,
                entry: token,
                derivedKeys: derivedKeys,
                derivationStyle: derivationStyle
            )
        } else {
            return try makeMultiWalletModels(
                walletPublicKeys: walletPublicKeys,
                entry: token
            )
        }
    }
}
