//
//  CardsRepository.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

class CardsRepository {
    var tangemSdk: TangemSdk!
    var ratesService: CoinMarketCapService!
    
    var cards = [String: CardViewModel]()
    
    func scan(_ completion: @escaping (Result<CardViewModel, Error>) -> Void) {
        Analytics.log(event: .readyToScan)
        tangemSdk.startSession(with: TapScanTask()) {[unowned self] result in
            switch result {
            case .failure(let error):
                Analytics.log(error: error)
                completion(.failure(error))
            case .success(let response):
                guard let cid = response.card.cardId else {
                    completion(.failure(TangemSdkError.unknownError))
                    return
                }
                Analytics.logScan(card: response.card)
                let vm = self.makeCardViewModel(card: response.card, verifyCardResponse: response.verifyResponse)
                self.cards[cid] = vm
                completion(.success(vm))
            }
        }
    }
    
    func createWallet(card: Card, _ completion: @escaping (Result<CardViewModel, Error>) -> Void) {
        tangemSdk.createWallet(cardId: card.cardId,
                               initialMessage: Message(header: nil,
                                                       body: "initial_message_create_wallet_body".localized)) { result in
                                                        switch result {
                                                        case .success(let response):
                                                            let vm =  self.updateViewModel(with: card.updating(with: response))
                                                            completion(.success(vm))
                                                        case .failure(let error):
                                                            Analytics.log(error: error)
                                                            completion(.failure(error))
                                                        }
        }
    }
    
    func purgeWallet(card: Card, _ completion: @escaping (Result<CardViewModel, Error>) -> Void) {
        tangemSdk.purgeWallet(cardId: card.cardId,
                              initialMessage: Message(header: nil,
                                                      body: "initial_message_purge_wallet_body".localized)) { result in
                                                        switch result {
                                                        case .success(let response):
                                                            let vm =  self.updateViewModel(with: card.updating(with: response))
                                                            completion(.success(vm))
                                                        case .failure(let error):
                                                            Analytics.log(error: error)
                                                            completion(.failure(error))
                                                        }
        }
    }
    
    func changeSecOption(_ option: SecurityManagementOption, card: Card, completion: @escaping (Result<Void, Error>) -> Void) {
        let vm = self.cards[card.cardId!]
        switch option {
        case .accessCode:
            tangemSdk.startSession(with: SetPinCommand(pinType: .pin1, isExclusive: true), cardId: card.cardId, initialMessage: Message(header: nil, body: "initial_message_change_access_code_body".localized)) { result in
                switch result {
                case .success:
                    vm?.card.isPin1Default = false
                    vm?.card.isPin2Default = true
                    vm?.updateCurrentSecOption()
                    completion(.success(()))
                case .failure(let error):
                    Analytics.log(error: error)
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
                    Analytics.log(error: error)
                    completion(.failure(error))
                }
            }
        case .passCode:
            tangemSdk.startSession(with: SetPinCommand(pinType: .pin2, isExclusive: true), cardId: card.cardId, initialMessage: Message(header: nil, body: "initial_message_change_passcode_body".localized)) { result in
                switch result {
                case .success:
                    vm?.card.isPin2Default = false
                    vm?.card.isPin1Default = true
                    vm?.updateCurrentSecOption()
                    completion(.success(()))
                case .failure(let error):
                    Analytics.log(error: error)
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
