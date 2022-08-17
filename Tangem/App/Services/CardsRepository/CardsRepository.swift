//
//  CardsRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol CardsRepository {
    func scan(with batch: String?, _ completion: @escaping (Result<CardViewModel, Error>) -> Void)
    func scanPublisher(with batch: String?) ->  AnyPublisher<CardViewModel, Error>
}

private struct CardsRepositoryKey: InjectionKey {
    static var currentValue: CardsRepository = CommonCardsRepository()
}

extension InjectedValues {
    var cardsRepository: CardsRepository {
        get { Self[CardsRepositoryKey.self] }
        set { Self[CardsRepositoryKey.self] = newValue }
    }
}

extension CardsRepository {
    func scanPublisher(with batch: String? = nil) ->  AnyPublisher<CardViewModel, Error> {
        scanPublisher(with: batch)
    }
}

protocol ScanListener {
    func onScan(cardInfo: CardInfo)
}

enum CardsRepositoryError: Error {
    case noCard
}
