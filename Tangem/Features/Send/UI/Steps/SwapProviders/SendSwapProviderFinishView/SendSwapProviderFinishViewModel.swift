//
//  SendSwapProviderFinishViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
import TangemExpress

class SendSwapProviderFinishViewModel: ObservableObject, Identifiable {
    let title: String
    let providerType: String
    let providerIcon: URL?

    @Published var subtitle: String = ""

    init(tokenItem: TokenItem, provider: ExpressAvailableProvider) {
        title = provider.provider.name
        providerType = provider.provider.type.title
        providerIcon = provider.provider.imageURL

        if let quote = provider.getState().quote {
            let source = BalanceFormatter().formatCryptoBalance(1, currencyCode: tokenItem.currencySymbol)
            subtitle = "\(source) \(AppConstants.approximatelyEqualSign) \(quote.rate.formatted())"
        }
    }
}
