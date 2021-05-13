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

enum WalletConnectCardScannerError: LocalizedError {
    case noCardId, noEthereumWallet
    
    var errorDescription: String? {
        switch self {
        case .noCardId: return "wallet_connect_scanner_error_no_card_id".localized
        case .noEthereumWallet: return "wallet_connect_scanner_error_no_ethereum_wallet".localized
        }
    }
}

class WalletConnectCardScanner {
    weak var assembly: Assembly!
    weak var tangemSdk: TangemSdk!
    
    func scanCard() -> AnyPublisher<WalletInfo, Error> {
        return Future { promise in
            self.tangemSdk.scanCard(initialMessage: Message(header: "wallet_connect_scan_card_message".localized)) { result in
                switch result {
                case .success(let card):
                    do {
                        promise(.success(try self.walletInfo(for: card)))
                    } catch {
                        print("Failed to receive wallet info for: \(card)")
                        promise(.failure(error))
                    }
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func walletInfo(for card: Card) throws -> WalletInfo {
        guard let cid = card.cardId else {
            throw WalletConnectCardScannerError.noCardId
        }
        
        let wallets = assembly.loadWallets(from: CardInfo(card: card))
        
        guard let wallet = wallets.first(where: { $0.wallet.blockchain == .ethereum(testnet: false) || $0.wallet.blockchain == .ethereum(testnet: true) })?.wallet else {
            throw WalletConnectCardScannerError.noEthereumWallet
        }
        
        return WalletInfo(cid: cid,
                          walletPublicKey: wallet.publicKey,
                          isTestnet: card.isTestnet ?? false)
    }
    
}
