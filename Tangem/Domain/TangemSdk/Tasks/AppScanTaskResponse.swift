//
//  AppScanTaskResponse.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct AppScanTaskResponse {
    let card: Card
    let walletData: DefaultWalletData
    let primaryCard: PrimaryCard?

    func getCardInfo() -> CardInfo {
        let cardInfo = CardInfo(
            card: CardDTO(card: card),
            walletData: walletData,
            primaryCard: primaryCard,
            associatedCardIds: []
        )

        return cardInfo
    }
}
