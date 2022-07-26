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
    var didScanPublisher: PassthroughSubject<CardInfo, Never> { get }

    func scan(with batch: String?, _ completion: @escaping (Result<ScanResult, Error>) -> Void)
    func scanPublisher(with batch: String?) ->  AnyPublisher<ScanResult, Error>
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
    func scanPublisher(with batch: String? = nil) ->  AnyPublisher<ScanResult, Error> {
        scanPublisher(with: batch)
    }
}

protocol ScanListener {
    func onScan(cardInfo: CardInfo)
}

enum CardsRepositoryError: Error {
    case noCard
}
