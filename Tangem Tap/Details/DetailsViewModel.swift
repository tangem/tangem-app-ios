//
//  DetailsViewModel.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import BlockchainSdk

class DetailsViewModel: ViewModel {
    @Published var navigation: NavigationCoordinator! {
        didSet {
            navigation.objectWillChange
                .receive(on: RunLoop.main)
                .sink { [weak self] in
                    self?.objectWillChange.send()
                }
                .store(in: &bag)
        }
    }
    var assembly: Assembly!
    var cardsRepository: CardsRepository!
    var bag = Set<AnyCancellable>()
    
    @Binding var cardState: CardState { //todo: is bindind needed?
        didSet {
            if let cardModel = cardState.cardModel {
                self.canPurgeWallet = cardModel.canPurgeWallet
            } else {
                self.canPurgeWallet = false
            }
        }
    }
    
    @Published var canPurgeWallet: Bool = false
    
//    func bind() {
//        bag = Set<AnyCancellable>()
//        Just(cardState) //todo check it
//            .sink { [unowned self] state in
//                if let cardModel = state?.cardModel {
//                    self.canPurgeWallet = cardModel.canPurgeWallet
//                } else {
//                    self.canPurgeWallet = false
//                }
//            }
//            .store(in: &bag)
//    }
//
    
    init(cardState: Binding<CardState>) {
        self._cardState = cardState
    }
    
    func purgeWallet(completion: @escaping (Result<Void, Error>) -> Void ) {
        guard let cardInfo = cardState.card else {
            return
        }
        
        cardsRepository.purgeWallet(card: cardInfo.card) { [weak self] result in
            switch result {
            case .success(let state):
                guard let self = self else { return }
                
                self.cardState = state
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
                break
            }
        }
    }
}
