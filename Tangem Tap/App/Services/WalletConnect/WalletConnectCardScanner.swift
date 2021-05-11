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

enum WalletConnectCardScannerError: Error {
    case noCardId, noEthereumWallet, noPublicKey
}

class WalletConnectCardScanner {
    weak var assembly: Assembly!
    weak var tangemSdk: TangemSdk!
    
    func scanCard() -> AnyPublisher<WalletInfo, Error> {
        return Future { promise in
            self.tangemSdk.scanCard(initialMessage: Message(header: "Scan card to bind to wallet connect")) { result in
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
        
        guard let wallet = card.wallets.first(where: { $0.curve == .secp256k1 }) else {
            throw WalletConnectCardScannerError.noEthereumWallet
        }
        
        guard let walletPublicKey = wallet.publicKey else {
            throw WalletConnectCardScannerError.noPublicKey
        }
        
        return WalletInfo(cid: cid,
                          walletPublicKey: walletPublicKey,
                          isTestnet: card.isTestnet ?? false)
    }
    
}
