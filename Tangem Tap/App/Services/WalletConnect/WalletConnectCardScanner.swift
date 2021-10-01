//
//  WalletConnectCardScanner.swift
//  Tangem Tap
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
                self?.tangemSdk.startSession(with: TapScanTask(), initialMessage: Message(header: "wallet_connect_scan_card_message".localized)) { result in
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
        
        var wallet: Wallet
        
        if cardsRepository.lastScanResult.cardModel?.cardInfo.card.cardId == cardInfo.card.cardId {
            let model = cardsRepository.lastScanResult.cardModel!
            if let targetWallet = findWallet(in: model.wallets ?? []) {
                wallet = targetWallet
            } else {
                model.addBlockchain(blockchain)
                wallet = model.wallets!.first(where: { $0.blockchain == blockchain })!
            }
            
        } else {
            let tokenRepoCardId = tokenItemsRepository.cardId
            tokenItemsRepository.setCard(cardInfo.card.cardId)
            
            if let targetWallet = findWallet(in: assembly.loadWallets(from: cardInfo).map { $0.wallet }) {
                wallet = targetWallet
            } else {
                tokenItemsRepository.append(.blockchain(blockchain))
                wallet = assembly.makeWallets(from: cardInfo, blockchains: [blockchain]).first!.wallet
            }
            tokenItemsRepository.setCard(tokenRepoCardId)
            
        }
        
        scannedCardsRepository.add(cardInfo.card)
        return WalletInfo(cid: cardInfo.card.cardId,
                          walletPublicKey: wallet.publicKey,
                          blockchain: blockchain,
                          chainId: chainId)
    }
    
}
