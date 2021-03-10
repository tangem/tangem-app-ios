//
//  MainViewModel.swift
//  TangemClip
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class MainViewModel: ObservableObject {
    
    @Published var isRefreshing: Bool = false
    
    @Published var cardNumber: String
    @Published var cardUrl: String? {
        didSet {
            objectWillChange.send()
        }
    }
    
    var isMultiWallet: Bool { false }
    
    let defaults: UserDefaults = UserDefaults(suiteName: "group.com.tangem.Tangem") ?? .standard
    unowned var cardsRepository: CardsRepository
    
    init(cid: String, cardsRepository: CardsRepository) {
        cardNumber = cid
        self.cardsRepository = cardsRepository
    }
    
    func scanCard() {
        cardsRepository.scan { (result) in
            switch result {
            case .success(let result):
                self.cardNumber = result.card?.cardId ?? "Unknown"
            case .failure(let error):
                print(error)
            }
        }
    }
    
}
