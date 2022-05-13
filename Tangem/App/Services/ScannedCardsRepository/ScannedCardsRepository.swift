//
//  ScannedCardsRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

protocol ScannedCardsRepository {
    var cards: [String: SavedCard] { get }
    func add(_ cardInfo: CardInfo)
}

private struct ScannedCardsRepositoryKey: InjectionKey {
    static var currentValue: ScannedCardsRepository = CommonScannedCardsRepository()
}

extension InjectedValues {
    var scannedCardsRepository: ScannedCardsRepository {
        get { Self[ScannedCardsRepositoryKey.self] }
        set { Self[ScannedCardsRepositoryKey.self] = newValue }
    }
}
