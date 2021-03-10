//
//  AmountType+.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import SwiftUI

extension Wallet {
    @ViewBuilder func getImageView(for amountType: Amount.AmountType) -> some View {
        if amountType == .coin, let name = blockchain.imageName {
            Image(name)
        } else if let token = amountType.token {
            CircleImageView(name: token.name, color: token.color)
        } else {
            CircleImageView(name: blockchain.displayName,
                            color: Color.tangemTapGrayLight4)
        }
    }
}
