//
//  PriceAlertsWalletSelectorViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

// Skeleton: the wallet list, "Don't ask again" and fan-out subscribe are [REDACTED_INFO].
final class PriceAlertsWalletSelectorViewModel: ObservableObject {
    let tokenId: PriceAlertTokenId
    let closeAction: () -> Void

    init(tokenId: PriceAlertTokenId, closeAction: @escaping () -> Void) {
        self.tokenId = tokenId
        self.closeAction = closeAction
    }
}
