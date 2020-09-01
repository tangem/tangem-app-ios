//
//  TangemSdkService.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

class TangemSdkService: ObservableObject {
    var cards = [String: CardViewModel]()
    
    lazy var tangemSdk: TangemSdk = {
        let sdk = TangemSdk()
        return sdk
    }()
    
    func scan(_ completion: @escaping (Result<CardViewModel, Error>) -> Void) {
        tangemSdk.startSession(with: TapScanTask()) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))  //[REDACTED_TODO_COMMENT]
            case .success(let response):
                guard let cid = response.card.cardId else {
                    completion(.failure(TangemSdkError.unknownError))
                    return
                }
                
                let vm = CardViewModel(card: response.card, verifyCardResponse: response.verifyResponse)
                self.cards[cid] = vm
                completion(.success(vm))
            }
        }
    }
    
    func createWallet(cardId: String?, _ completion: @escaping (Result<CardViewModel, Error>) -> Void) {
        let createWalletTask = CreateWalletReadTask()
        tangemSdk.startSession(with: createWalletTask, cardId: cardId) { result in
            switch result {
            case .success(let response):
                guard let _ = response.card.cardId else {
                    completion(.failure(TangemSdkError.unknownError))
                    return
                }
                let vm =  self.updateViewModel(with: response.card)
                completion(.success(vm))
            case .failure(let error):
                completion(.failure(error))
                break
            }
        }
    }
    
    func purgeWallet(cardId: String?, _ completion: @escaping (Result<CardViewModel, Error>) -> Void) {
        let purgeWalletTask = PurgeWalletReadTask()
        tangemSdk.startSession(with: purgeWalletTask, cardId: cardId) { result in
            switch result {
            case .success(let response):
                guard let _ = response.card.cardId else {
                    completion(.failure(TangemSdkError.unknownError))
                    return
                }
                let vm =  self.updateViewModel(with: response.card)
                completion(.success(vm))
            case .failure(let error):
                completion(.failure(error))
                break
            }
        }
    }
    
    private func updateViewModel(with card: Card) -> CardViewModel {
        let cid = card.cardId!
        let oldVerifyResponse = self.cards[cid]?.verifyCardResponse
        let vm = CardViewModel(card: card, verifyCardResponse: oldVerifyResponse)
        self.cards[cid] = vm
        return vm
    }
}
