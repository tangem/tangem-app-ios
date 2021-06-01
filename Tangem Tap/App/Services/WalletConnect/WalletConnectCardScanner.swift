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
    case noCardId, notValidCard
    
    var errorDescription: String? {
        switch self {
        case .noCardId: return "wallet_connect_scanner_error_no_card_id".localized
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
    
    func scanCard() -> AnyPublisher<WalletInfo, Error> {
        Deferred {
            Future { [weak self] promise in
                self?.tangemSdk.startSession(with: TapScanTask(), initialMessage: Message(header: "wallet_connect_scan_card_message".localized)) { result in
                    guard let self = self else { return }
                    
                    switch result {
                    case .success(let card):
                        do {
                            promise(.success(try self.walletInfo(for: card.card)))
                        } catch {
                            print("Failed to receive wallet info for with id: \(card.card.cardId ?? "")")
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
    
    func walletInfo(for card: Card) throws -> WalletInfo {
        guard let cid = card.cardId else {
            throw WalletConnectCardScannerError.noCardId
        }
        
        guard card.isMultiWallet,
            card.wallets.contains(where: { $0.curve == .secp256k1 }) else {
            throw WalletConnectCardScannerError.notValidCard
        }
        
        let cardInfo = CardInfo(card: card)
        let isLastScannedCard: Bool
        let cardModel: CardViewModel
        var tokenRepoCardId: String?
        
        if cardsRepository.lastScanResult.cardModel?.cardInfo.card.cardId == cid {
            isLastScannedCard = true
            cardModel = cardsRepository.lastScanResult.cardModel!
        } else {
            tokenRepoCardId = tokenItemsRepository.cardId
            isLastScannedCard = false
            tokenItemsRepository.setCard(cid)
            cardModel = assembly.makeCardModel(from: cardInfo)
        }
        
        let wallets = cardModel.wallets ?? []
        
        let wallet: Wallet
        if let ethWallet = wallets.first(where: { $0.blockchain == .ethereum(testnet: false) || $0.blockchain == .ethereum(testnet: true) }) {
            wallet = ethWallet
        } else {
            let blockchain = Blockchain.ethereum(testnet: false)
            if isLastScannedCard {
                cardModel.addBlockchain(blockchain)
                wallet = cardModel.wallets!.first(where: { $0.blockchain == blockchain })!
            } else {
                tokenItemsRepository.append(.blockchain(blockchain))
                wallet = assembly.makeWallets(from: cardInfo, blockchains: [blockchain]).first!.wallet
            }
        }
        if let tokenRepoCardId = tokenRepoCardId {
            tokenItemsRepository.setCard(tokenRepoCardId)
        }
        
        scannedCardsRepository.add(card)
        return WalletInfo(cid: cid,
                          walletPublicKey: wallet.publicKey,
                          isTestnet: card.isTestnet ?? false)
    }
    
}
