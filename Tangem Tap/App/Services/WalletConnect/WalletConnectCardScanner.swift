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
        
        let tokenRepoCardId = tokenItemsRepository.cardId
        let needSwapCards = tokenRepoCardId != cid
        if needSwapCards {
            tokenItemsRepository.setCard(cid)
        }
        let cardInfo = CardInfo(card: card)
        let wallets = assembly.loadWallets(from: cardInfo)
        
        let wallet: Wallet
        if let ethWallet = wallets.first(where: { $0.wallet.blockchain == .ethereum(testnet: false) || $0.wallet.blockchain == .ethereum(testnet: true) })?.wallet {
            wallet = ethWallet
        } else {
            let blockchain = Blockchain.ethereum(testnet: false)
            tokenItemsRepository.append(.blockchain(blockchain))
            wallet = assembly.makeWallets(from: cardInfo, blockchains: [blockchain]).first!.wallet
        }
        if needSwapCards {
            tokenItemsRepository.setCard(tokenRepoCardId)
        }
        
        scannedCardsRepository.add(card)
        return WalletInfo(cid: cid,
                          walletPublicKey: wallet.publicKey,
                          isTestnet: card.isTestnet ?? false)
    }
    
}
