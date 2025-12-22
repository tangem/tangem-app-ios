//
//  TokenItemPromoProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI

protocol TokenItemPromoProvider {
    var promoWalletModelPublisher: AnyPublisher<TokenItemPromoParams?, Never> { get }
    func hidePromoBubble()
}

struct TokenItemPromoParams: Equatable {
    let walletModelId: WalletModelId
    let message: String
    let icon: Image
    let appStorageKey: String
}
