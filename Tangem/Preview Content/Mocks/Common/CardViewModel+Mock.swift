//
//  CardViewModel+Mock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

extension CardViewModel {
    static let mock = CardViewModel(
        cardInfo: CardInfo(card: .init(card: .walletWithBackup), walletData: .none, name: "", artwork: .noArtwork, primaryCard: nil)
    )
}
