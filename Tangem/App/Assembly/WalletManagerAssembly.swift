//
//  WalletManagerAssembly.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
#if !CLIP
import BlockchainSdk
#endif

class WalletManagerAssembly {
    let factory: WalletManagerFactory
    let tokenItemsRepository: TokenItemsRepository
    
    init(factory: WalletManagerFactory, tokenItemsRepository: TokenItemsRepository) {
        self.factory = factory
        self.tokenItemsRepository = tokenItemsRepository
    }
    
    func makeAllWalletManagers(for cardInfo: CardInfo) -> [WalletManager] {
        //If this card is Twin, return twinWallet
        if cardInfo.card.isTwinCard {
            if let savedPairKey = cardInfo.twinCardInfo?.pairPublicKey,
               let publicKey = cardInfo.card.wallets.first?.publicKey,
               let twinManager = try? factory.makeTwinWalletManager(from: cardInfo.card.cardId,
                                                                    walletPublicKey: publicKey,
                                                                    pairKey: savedPairKey,
                                                                    isTestnet: false) {
                return [twinManager]
            }
            
            //temp for bugged case
            if cardInfo.twinCardInfo?.pairPublicKey == nil,
               let wallet = cardInfo.card.wallets.first,
               let bitcoinManager = try? factory.makeWalletManager(cardId: cardInfo.card.cardId,
                                                                   blockchain: .bitcoin(testnet: false),
                                                                   walletPublicKey: wallet.publicKey ) {
                return [bitcoinManager]
            }
            
            return []
        }
        
        //If this card supports multiwallet feature, load all saved tokens from persistent storage
        if cardInfo.isMultiWallet {
            var walletManagers: [WalletManager] = []
            let tokenItems = tokenItemsRepository.getItems(for: cardInfo.card.cardId)
         
            if !tokenItems.isEmpty {
                //Load tokens if exists
                let savedBlockchains = Set(tokenItems.map { $0.blockchain })
                let savedTokens = tokenItems.compactMap { $0.token }
                let groupedTokens = Dictionary(grouping: savedTokens, by: { $0.blockchain })
                
                walletManagers.append(contentsOf: makeWalletManagers(from: cardInfo,
                                                                     blockchains: Array(savedBlockchains)
                                                                        .sorted{$0.displayName < $1.displayName}))
                groupedTokens.forEach { tokenGroup in
                    if let manager = walletManagers.first(where: {$0.wallet.blockchain == tokenGroup.key }) {
                        manager.addTokens(tokenGroup.value)
                    }
                }
            }
            
            //Try found default card wallet
            if let nativeWalletManager = makeNativeWalletManager(from: cardInfo),
               !walletManagers.contains(where: { $0.wallet.blockchain == nativeWalletManager.wallet.blockchain }) {
                walletManagers.append(nativeWalletManager)
            }
            
            return walletManagers
        }
        
        //Old single walled ada cards or Tangem Notes
        if let nativeWalletManager = makeNativeWalletManager(from: cardInfo) {
            return [nativeWalletManager]
        }
        
        return []
    }
    
    ///Try to make WalletManagers for blockchains with suitable wallet
    func makeWalletManagers(from cardInfo: CardInfo, blockchains: [Blockchain]) -> [WalletManager] {
        return blockchains.compactMap { blockchain in
            if let wallet = cardInfo.card.wallets.first(where: { $0.curve == blockchain.curve }) {
                return makeWalletManager(cardId: cardInfo.card.cardId,
                                         walletPublicKey: wallet.publicKey,
                                         blockchain: blockchain,
                                         seedKey: wallet.extendedPublicKey,
                                         derivedKeys: cardInfo.derivedKeys)
            }
            
            return nil
        }
    }
    
    func makeWalletManagers(from cardDto: SavedCard, blockchains: [Blockchain]) -> [WalletManager] {
        return blockchains.compactMap { blockchain in
            if let wallet = cardDto.wallets.first(where: { $0.curve == blockchain.curve }) {
                return makeWalletManager(cardId: cardDto.cardId,
                                         walletPublicKey: wallet.publicKey,
                                         blockchain: blockchain,
                                         seedKey: wallet.extendedPublicKey,
                                         derivedKeys: cardDto.derivedKeys)
            }
            
            return nil
        }
    }
    
    private func makeWalletManager(cardId: String,
                                   walletPublicKey: Data,
                                   blockchain: Blockchain,
                                   seedKey: ExtendedPublicKey?,
                                   derivedKeys: [Data: [ExtendedPublicKey]]) -> WalletManager? {
        if blockchain.curve == .secp256k1 || blockchain.curve == .ed25519, let seedKey = seedKey {
            guard let derivedKeys = derivedKeys[seedKey.compressedPublicKey],
                  let derivedKey = derivedKeys.first(where: { $0.derivationPath == blockchain.derivationPath }) else {
                return nil
            }
            
            return try? factory.makeWalletManager(cardId: cardId,
                                                           blockchain: blockchain,
                                                           seedKey: seedKey,
                                                           derivedKey: derivedKey)
        } else {
            return try? factory.makeWalletManager(cardId: cardId,
                                                           blockchain: blockchain,
                                                           walletPublicKey: walletPublicKey)
        }
    }
    
    /// Try to load native walletmanager from card
    private func makeNativeWalletManager(from cardInfo: CardInfo) -> WalletManager? {
        if let defaultBlockchain = cardInfo.defaultBlockchain,
           let cardWalletManager = makeWalletManagers(from: cardInfo, blockchains: [defaultBlockchain]).first {
            if let defaultToken = cardInfo.defaultToken {
                cardWalletManager.addToken(defaultToken)
            }
            
            return cardWalletManager
        }
        
        return nil
    }
}
