//
//  WalletConnectCardScanner.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import Combine
import BlockchainSdk

enum WalletConnectCardScannerError: LocalizedError {
    case notValidCard
    
    var errorDescription: String? {
        switch self {
        case .notValidCard: return "wallet_connect_scanner_error_not_valid_card".localized
        }
    }
}

class WalletConnectCardScanner {
    weak var assembly: Assembly!
    weak var tangemSdk: TangemSdk!
    weak var scannedCardsRepository: ScannedCardsRepository!
    weak var tokenItemsRepository: TokenItemsRepository!
    weak var cardsRepository: CardsRepository!
    
    func scanCard(for wcNetwork: WalletConnectNetwork) -> AnyPublisher<WalletInfo, Error> {
        Deferred {
            Future { [weak self] promise in
                guard let self = self else { return }
                
                self.tangemSdk.startSession(with: AppScanTask(tokenItemsRepository: self.tokenItemsRepository, userPrefsService: nil, shouldDeriveWC: true), initialMessage: Message(header: "wallet_connect_scan_card_message".localized)) {[weak self] result in
                    guard let self = self else { return }
                    
                    switch result {
                    case .success(let card):
                        do {
                            promise(.success(try self.walletInfo(for: card.getCardInfo(), wcNetwork: wcNetwork)))
                        } catch {
                            print("Failed to receive wallet info for with id: \(card.card.cardId)")
                            promise(.failure(error))
                        }
                    case .failure(let error):
                        promise(.failure(error))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func walletInfo(for cardInfo: CardInfo, wcNetwork: WalletConnectNetwork) throws -> WalletInfo {
        guard cardInfo.isMultiWallet,
              cardInfo.card.wallets.contains(where: { $0.curve == .secp256k1 }) else {
            throw WalletConnectCardScannerError.notValidCard
        }
        
        var chainId: Int?
        guard let blockchain = wcNetwork.blockchain else {
            throw WalletConnectServiceError.unsupportedNetwork
        }
        
        if case let .eth(id) = wcNetwork {
            chainId = id
        }
        
        func findWallet(in wallets: [Wallet]) -> Wallet? {
            wallets.first(where: { $0.blockchain == blockchain })
        }
        
        var wallet: Wallet? = nil
        
        if let existingCardModel = cardsRepository.lastScanResult.cardModel,
           existingCardModel.cardInfo.card.cardId == cardInfo.card.cardId {
            if let targetWallet = findWallet(in: existingCardModel.wallets ?? []) {
                wallet = targetWallet
            } else {
                let newDerivations = cardInfo.derivedKeys
                if !newDerivations.isEmpty {
                    for newDerivation in newDerivations {
                        if let existingDerivations = existingCardModel.cardInfo.derivedKeys[newDerivation.key] {
                            let uniqueDerivations = Set(newDerivation.value + existingDerivations)
                            existingCardModel.cardInfo.derivedKeys.updateValue(Array(uniqueDerivations), forKey: newDerivation.key)
                        } else {
                            existingCardModel.cardInfo.derivedKeys.updateValue(newDerivation.value, forKey: newDerivation.key)
                        }
                    }
                }
                
                existingCardModel.addBlockchain(blockchain)
                wallet = existingCardModel.wallets?.first(where: { $0.blockchain == blockchain })
            }
        } else {
            if let targetWallet = findWallet(in: assembly.makeAllWalletModels(from: cardInfo).map { $0.wallet }) {
                wallet = targetWallet
            } else {
                tokenItemsRepository.append(.blockchain(blockchain), for: cardInfo.card.cardId)
                wallet = assembly.makeWalletModels(from: cardInfo, blockchains: [blockchain]).first?.wallet
            }
        }
        
        guard let wallet = wallet else {
            throw WalletConnectCardScannerError.notValidCard
        }
        
        scannedCardsRepository.add(cardInfo)
        
        let derivedKey = wallet.publicKey.blockchainKey != wallet.publicKey.seedKey ? wallet.publicKey.blockchainKey : nil
        
        return WalletInfo(cid: cardInfo.card.cardId,
                          walletPublicKey: wallet.publicKey.seedKey,
                          derivedPublicKey: derivedKey,
                          derivationPath: wallet.publicKey.derivationPath,
                          blockchain: blockchain,
                          chainId: chainId)
    }
    
}
