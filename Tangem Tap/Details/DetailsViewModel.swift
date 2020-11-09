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
    var assembly: Assembly!
    var cardsRepository: CardsRepository!
    var ratesService: CoinMarketCapService!
    
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
   
    @Published private(set) var cardModel: CardViewModel {
        didSet {
            cardModel.objectWillChange
                .receive(on: RunLoop.main)
                .sink { [weak self] in
                    self?.objectWillChange.send()
                }
                .store(in: &bag)
        }
    }
    
    private var bag = Set<AnyCancellable>()
    
    init(cardModel: CardViewModel) {
        self.cardModel = cardModel
    }
    
    func purgeWallet(completion: @escaping (Result<Void, Error>) -> Void ) {
        cardModel.purgeWallet() {result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
                break
            }
        }
    }
}
