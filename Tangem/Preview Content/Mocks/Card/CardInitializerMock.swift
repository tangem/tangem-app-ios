//
//  CardInitializerMock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

class CardInitializerMock: CardInitializer {
    var shouldReset: Bool = false

    func initializeCard(mnemonic: Mnemonic?, passphrase: String?, completion: @escaping (Result<CardInfo, TangemSdkError>) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            let cardInfo = CardInfo(
                card: .init(card: CardMock.wallet.card),
                walletData: .none,
                primaryCard: nil,
                associatedCardIds: []
            )
            completion(.success(cardInfo))
        }
    }
}
