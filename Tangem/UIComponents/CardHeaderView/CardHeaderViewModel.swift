//
//  CardHeaderViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol CardHeaderInfoProvider: AnyObject {
    var cardNamePublisher: AnyPublisher<String, Never> { get }
    var numberOfCardsPublisher: AnyPublisher<Int, Never> { get }
    var isWalletImported: Bool { get }
}

final class CardHeaderViewModel: ObservableObject {
    
    let isWalletImported: Bool
    
    @Published private(set) var cardName: String = ""
    @Published private(set) var numberOfCardsText: String = ""
    
    private let cardInfoProvider: CardHeaderInfoProvider
    
    private var bag: Set<AnyCancellable> = []
    
    init(cardInfoProvider: CardHeaderInfoProvider) {
        self.cardInfoProvider = cardInfoProvider
        
        isWalletImported = cardInfoProvider.isWalletImported
        bind()
    }
    
    private func bind() {
        cardInfoProvider.cardNamePublisher
            .receive(on: DispatchQueue.main)
            .weakAssign(to: \.cardName, on: self)
            .store(in: &bag)
        
        cardInfoProvider.numberOfCardsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] numberOfCards in
                self?.numberOfCardsText = Localization.cardLabelCardCount(numberOfCards)
            }
            .store(in: &bag)
    }
}
