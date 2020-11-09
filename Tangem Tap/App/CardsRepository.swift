//
//  CardsRepository.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

struct CardInfo {
    var card: Card
    var verificationState: VerifyCardState?
    var artworkInfo: ArtworkInfo?
}

enum CardState: Equatable {
    case new
    case loaded(model: CardViewModel)
    case unsupported
    case empty(cardInfo: CardInfo)
    
    var wallet: Wallet? {
        switch self {
        case .loaded(let model):
            return model.walletManager.wallet
        default:
            return nil
        }
    }
    
    var cardModel: CardViewModel? {
        switch self {
        case .loaded(let model):
            return model
        default:
            return nil
        }
    }
    
    var card: CardInfo? {
        switch self {
        case .empty(let cardInfo):
            return cardInfo
        case .loaded(let model):
            return model.cardInfo
        default:
            return nil
        }
    }
    
    static func == (lhs: CardState, rhs: CardState) -> Bool {
        if case .loaded = lhs, case .loaded = rhs {
            return true
        }
        
        if case .unsupported = lhs, case .unsupported = rhs {
            return true
        }
        
        if case .empty = lhs, case .empty = rhs {
            return true
        }
        
        if case .new = lhs, case .new = rhs {
            return true
        }
        
        return false
    }
}

class CardsRepository {
    var tangemSdk: TangemSdk!
    var ratesService: CoinMarketCapService!
    var workaroundsService: WorkaroundsService!
    
    var cards = [String: CardState]()
    
    
    func scan(_ completion: @escaping (Result<CardState, Error>) -> Void) {
        Analytics.log(event: .readyToScan)
        tangemSdk.startSession(with: TapScanTask()) {[unowned self] result in
            switch result {
            case .failure(let error):
                Analytics.log(error: error)
                completion(.failure(error))
            case .success(let response):
                guard response.card.cardId != nil else {
                    completion(.failure(TangemSdkError.unknownError))
                    return
                }
                
                Analytics.logScan(card: response.card)
                
                let cardInfo = CardInfo(card: response.card,
                                        verificationState: response.verifyResponse.verificationState,
                                        artworkInfo: response.verifyResponse.artworkInfo)
                
                let state = self.makeState(card: response.card, info: cardInfo)
                self.cards[response.card.cardId!] = state
                completion(.success(state))
            }
        }
    }
    
    func createWallet(cardId: String, _ completion: @escaping (Result<CardState, Error>) -> Void) {
        let state = cards[cardId]!
        
        tangemSdk.createWallet(cardId: cardId,
                               initialMessage: Message(header: nil,
                                                       body: "initial_message_create_wallet_body".localized)) {[unowned self] result in
                                                        switch result {
                                                        case .success(let response):
                                                            let state = self.makeState(card: cardInfo.card.updating(with: response),
                                                                                       info: cardInfo)
                                                            self.cards[cardId] = state
                                                            completion(.success(state))
                                                        case .failure(let error):
                                                            Analytics.log(error: error)
                                                            completion(.failure(error))
                                                        }
        }
    }
    
    func purgeWallet(cardId: String , _ completion: @escaping (Result<CardState, Error>) -> Void) {
        let cardInfo = cards[cardId]!
        
        tangemSdk.purgeWallet(cardId: cardId,
                              initialMessage: Message(header: nil,
                                                      body: "initial_message_purge_wallet_body".localized)) { result in
                                                        switch result {
                                                        case .success(let response):
                                                            let state = self.makeState(card: cardInfo.card.updating(with: response),
                                                                                       info: cardInfo)
                                                            self.cards[cardId] = state
                                                            completion(.success(state))
                                                        case .failure(let error):
                                                            Analytics.log(error: error)
                                                            completion(.failure(error))
                                                        }
        }
    }
    
    func changeSecOption(_ option: SecurityManagementOption, cardId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let state = self.cards[cardId]
        
        switch option {
        case .accessCode:
            tangemSdk.startSession(with: SetPinCommand(pinType: .pin1, isExclusive: true),
                                   cardId: cardId,
                                   initialMessage: Message(header: nil, body: "initial_message_change_access_code_body".localized)) { result in
                switch result {
                case .success:
                    vm?.cardInfo.card.isPin1Default = false
                    vm?.cardInfo.card.isPin2Default = true
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
                    vm?.cardInfo.card.isPin1Default = true
                    vm?.cardInfo.card.isPin2Default = true
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
                    vm?.cardInfo.card.isPin2Default = false
                    vm?.cardInfo.card.isPin1Default = true
                    vm?.updateCurrentSecOption()
                    completion(.success(()))
                case .failure(let error):
                    Analytics.log(error: error)
                    completion(.failure(error))
                }
            }
        }
    }
    
    private func makeState(card: Card, info: CardInfo) -> CardState {
        if let walletManager = WalletManagerFactory().makeWalletManager(from: card) {
            let vm = CardViewModel(cardInfo: info, walletManager: walletManager)
            vm.ratesService = self.ratesService
            vm.workaroundsService = workaroundsService
            
            if let payIdService = PayIDService.make(from: walletManager.wallet.blockchain) {
                payIdService.workaroundsService = workaroundsService
                vm.payIDService = payIdService
            }
            vm.update()
            return .loaded(model: vm)
        } else {
            let isCardSupported = WalletManagerFactory().isBlockchainSupported(card)
            self.cards.removeValue(forKey: card.cardId!)
            if isCardSupported {
                return .empty(cardInfo: info)
            } else {
                return .unsupported
            }
        }
    }
}
