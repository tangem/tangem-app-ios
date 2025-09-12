//
//  AccountItemViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemAssets
import SwiftUI

final class AccountItemViewModel: ObservableObject {
    @Published var balanceFiat: LoadableTokenBalanceView.State
    @Published var priceChangeState: TokenPriceChangeView.State

    let name: String

    init() {
        // Stubs for testing
        balanceFiat = .loaded(text: .string("1,23 $"))
        name = "Main account"
        priceChangeState = .loaded(signType: .positive, text: "1,14 %")
    }

    var tokensCount: String {
        "24 tokens"
    }

    var imageData: (backgroundColor: Color, image: Image) {
        (.red, Assets.Accounts.airplane.image)
    }
}
