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
    var ratesService: CoinMarketCapService!
    
    var cards = [String: CardViewModel]()
    
    let excludeBatches = ["0027", "0030", "0031"]
    
    lazy var tangemSdk: TangemSdk = {
        let sdk = TangemSdk()
        return sdk
    }()
    
    func scan(_ completion: @escaping (Result<CardViewModel, Error>) -> Void) {
        tangemSdk.startSession(with: TapScanTask()) {[unowned self] result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response):
                guard let cid = response.card.cardId else {
                    completion(.failure(TangemSdkError.unknownError))
                    return
                }
                
                if let product = response.card.cardData?.productMask, !product.contains(ProductMask.note) { //filter product
                    completion(.failure(TangemSdkError.underlying(error: "alert_unsupported_card".localized)))
                    return
                }
                
                if let status = response.card.status { //filter status
                    if status == .notPersonalized {
                        completion(.failure(TangemSdkError.notPersonalized))
                        return
                    }
                    
                    if status == .purged {
                        completion(.failure(TangemSdkError.cardIsPurged))
                        return
                    }
                }
                
                if let batch = response.card.cardData?.batchId, self.excludeBatches.contains(batch) { //filter bach
                    completion(.failure(TangemSdkError.underlying(error: "alert_unsupported_card".localized)))
                    return
                }
                
                let vm = self.makeCardViewModel(card: response.card, verifyCardResponse: response.verifyResponse)
                self.cards[cid] = vm
                completion(.success(vm))
            }
        }
    }
    
    func createWallet(card: Card, _ completion: @escaping (Result<CardViewModel, Error>) -> Void) {
        tangemSdk.createWallet(cardId: card.cardId) { result in
            switch result {
            case .success(let response):
                let vm =  self.updateViewModel(with: card.updating(with: response))
                completion(.success(vm))
            case .failure(let error):
                completion(.failure(error))
                break
            }
        }
    }
    
    func purgeWallet(card: Card, _ completion: @escaping (Result<CardViewModel, Error>) -> Void) {
        tangemSdk.purgeWallet(cardId: card.cardId) { result in
            switch result {
            case .success(let response):
                let vm =  self.updateViewModel(with: card.updating(with: response))
                completion(.success(vm))
            case .failure(let error):
                completion(.failure(error))
                break
            }
        }
    }
    
    func changeSecOption(_ option: SecurityManagementOption, card: Card, completion: @escaping (Result<Void, Error>) -> Void) {
        let vm = self.cards[card.cardId!]
        switch option {
        case .accessCode:
            tangemSdk.changePin1(cardId: card.cardId) {result in
                switch result {
                case .success:
                    vm?.card.isPin1Default = false
                       vm?.updateCurrentSecOption()
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        case .longTap:
            tangemSdk.startSession(with: SetPinCommand(), cardId: card.cardId) {result in
                switch result {
                case .success:
                    vm?.card.isPin1Default = true
                    vm?.card.isPin2Default = true
                    vm?.updateCurrentSecOption()
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        case .passCode:
            tangemSdk.changePin2(cardId: card.cardId) {result in
                vm?.card.isPin2Default = false
                vm?.updateCurrentSecOption()
                switch result {
                case .success:
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    private func updateViewModel(with card: Card) -> CardViewModel {
        let cid = card.cardId!
        let oldVerifyResponse = self.cards[cid]!.verifyCardResponse!
        let vm = makeCardViewModel(card: card, verifyCardResponse: oldVerifyResponse)
        self.cards[cid] = vm
        return vm
    }
    
    private func makeCardViewModel(card: Card, verifyCardResponse: VerifyCardResponse) -> CardViewModel {
        let vm = CardViewModel(card: card, verifyCardResponse: verifyCardResponse)
        vm.ratesService = self.ratesService
        vm.update()
        return vm
    }
}
