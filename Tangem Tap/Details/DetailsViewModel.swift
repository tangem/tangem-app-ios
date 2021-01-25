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
import TangemSdk
import BlockchainSdk

class DetailsViewModel: ViewModel {
    weak var assembly: Assembly!
    weak var navigation: NavigationCoordinator!
    weak var cardsRepository: CardsRepository!
    weak var ratesService: CoinMarketCapService! {
        didSet {
            ratesService
                .$selectedCurrencyCodePublished
                .receive(on: RunLoop.main)
                .sink { [weak self] _ in
                    self?.objectWillChange.send()
                }
                .store(in: &bag)
        }
    }
    

    @Published var cardModel: CardViewModel! {
        didSet {
            cardModel.objectWillChange
                .receive(on: RunLoop.main)
                .sink { [weak self] in
                    self?.objectWillChange.send()
                }
                .store(in: &bag)
        }
    }
	
    var hasWallet: Bool {
        cardModel.hasWallet
    }
    
	var isTwinCard: Bool {
		cardModel.isTwinCard
	}
    
    var cardCid: String {
        guard let cardId = cardModel.cardInfo.card.cardId else { return "" }
        
        return isTwinCard ?
            TapTwinCardIdFormatter.format(cid: cardId, cardNumber: cardModel.cardInfo.twinCardInfo?.series?.number) :
            TapCardIdFormatter(cid: cardId).formatted()
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
