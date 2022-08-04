//
//  WalletManagerAssembly.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

class WalletManagerAssembly {
    @Injected(\.tokenItemsRepository) private var tokenItemsRepository: TokenItemsRepository
    @Injected(\.keysManager) private var keysManager: KeysManager

    private lazy var factory: WalletManagerFactory = {
        .init(config: keysManager.blockchainConfig)
    }()

    init() {}

    func makeAllWalletManagers(for cardInfo: CardInfo) -> [WalletManager] {
        // If this card is Twin, return twinWallet
        if cardInfo.card.isTwinCard {
            if let savedPairKey = cardInfo.twinCardInfo?.pairPublicKey,
               let publicKey = cardInfo.card.wallets.first?.publicKey,
               let twinManager = try? factory.makeTwinWalletManager(walletPublicKey: publicKey,
                                                                    pairKey: savedPairKey,
                                                                    isTestnet: false) {
                return [twinManager]
            }
            
            return []
        }

        // If this card supports multiwallet feature, load all saved tokens from persistent storage
        if cardInfo.isMultiWallet {
            var walletManagers: [WalletManager] = []
            let items = tokenItemsRepository.getItems(for: cardInfo.card.cardId)

            if !items.isEmpty {
                // Load tokens if exists
                walletManagers.append(contentsOf: makeWalletManagers(from: cardInfo, entries: items))
            }

            return walletManagers
        }

        // Old single walled ada cards or Tangem Notes
        if let nativeWalletManager = makeNativeWalletManager(from: cardInfo) {
            return [nativeWalletManager]
        }

        return []
    }

    /// Try to make WalletManagers for blockchains with suitable wallet
    func makeWalletManagers(from cardInfo: CardInfo, entries: [StorageEntry]) -> [WalletManager] {
        return entries.compactMap { entry in
            if let wallet = cardInfo.card.wallets.first(where: { $0.curve == entry.blockchainNetwork.blockchain.curve }),
               let manager = makeWalletManager(walletPublicKey: wallet.publicKey,
                                               blockchainNetwork: entry.blockchainNetwork,
                                               isHDWalletAllowed: cardInfo.card.settings.isHDWalletAllowed,
                                               derivedKeys: cardInfo.derivedKeys[wallet.publicKey] ?? [:])
            {
                manager.addTokens(entry.tokens)
                return manager
            }
            return nil
        }
    }

    func makeWalletManagers(from cardDto: SavedCard, blockchainNetworks: [BlockchainNetwork]) -> [WalletManager] {
        return blockchainNetworks.compactMap { network in
            if let wallet = cardDto.wallets.first(where: { $0.curve == network.blockchain.curve }) {
                return makeWalletManager(walletPublicKey: wallet.publicKey,
                                         blockchainNetwork: network,
                                         isHDWalletAllowed: wallet.isHdWalletAllowed,
                                         derivedKeys: cardDto.getDerivedKeys(for: wallet.publicKey))
            }

            return nil
        }
    }

    private func makeWalletManager(walletPublicKey: Data,
                                   blockchainNetwork: BlockchainNetwork,
                                   isHDWalletAllowed: Bool,
                                   derivedKeys: [DerivationPath: ExtendedPublicKey]) -> WalletManager? {
        if isHDWalletAllowed, blockchainNetwork.blockchain.curve == .secp256k1 || blockchainNetwork.blockchain.curve == .ed25519  {
            guard let derivationPath = blockchainNetwork.derivationPath,
                  let derivedKey = derivedKeys[derivationPath] else { return nil }

            return try? factory.makeWalletManager(blockchain: blockchainNetwork.blockchain,
                                                  seedKey: walletPublicKey,
                                                  derivedKey: derivedKey,
                                                  derivation: .custom(derivationPath))
        } else {
            return try? factory.makeWalletManager(blockchain: blockchainNetwork.blockchain,
                                                  walletPublicKey: walletPublicKey)
        }
    }

    /// Try to load native walletmanager from card
    private func makeNativeWalletManager(from cardInfo: CardInfo) -> WalletManager? {
        if let defaultBlockchain = cardInfo.defaultBlockchain {
            let network = BlockchainNetwork(defaultBlockchain, derivationPath: nil)
            let entry = StorageEntry(blockchainNetwork: network, tokens: [])
            if let cardWalletManager = makeWalletManagers(from: cardInfo, entries: [entry]).first {
                if let defaultToken = cardInfo.defaultToken {
                    cardWalletManager.addToken(defaultToken)
                }

                return cardWalletManager
            }

        }
        return nil
    }
}

// MARK: - Factory
extension WalletManagerAssembly {
    static func makeAllWalletModels(from cardInfo: CardInfo) -> [WalletModel] {
        let assembly = WalletManagerAssembly()
        let walletManagers = assembly.makeAllWalletManagers(for: cardInfo)
        return makeWalletModels(walletManagers: walletManagers,
                                derivationStyle: cardInfo.card.derivationStyle,
                                isDemoCard: cardInfo.card.isDemoCard)
    }

    static func makeWalletModels(from cardInfo: CardInfo, entries: [StorageEntry]) -> [WalletModel] {
        let assembly = WalletManagerAssembly()
        let walletManagers = assembly.makeWalletManagers(from: cardInfo, entries: entries)
        return makeWalletModels(walletManagers: walletManagers,
                                derivationStyle: cardInfo.card.derivationStyle,
                                isDemoCard: cardInfo.card.isDemoCard)
    }

    static func makeWalletModels(from cardDto: SavedCard, blockchainNetworks: [BlockchainNetwork]) -> [WalletModel] {
        let assembly = WalletManagerAssembly()
        let walletManagers = assembly.makeWalletManagers(from: cardDto, blockchainNetworks: blockchainNetworks)
        return makeWalletModels(walletManagers: walletManagers,
                                derivationStyle: cardDto.derivationStyle,
                                isDemoCard: false)
    }

    // Make walletModel from walletManager
    static private func makeWalletModels(walletManagers: [WalletManager],
                                         derivationStyle: DerivationStyle,
                                         isDemoCard: Bool) -> [WalletModel] {
        let items = SupportedTokenItems()
        return walletManagers.map { manager -> WalletModel in
            var demoBalance: Decimal? = nil
            if isDemoCard, let balance = items.predefinedDemoBalances[manager.wallet.blockchain] {
                demoBalance = balance
            }

            let model = WalletModel(walletManager: manager,
                                    derivationStyle: derivationStyle,
                                    demoBalance: demoBalance)

            model.initialize()
            return model
        }
    }
}
