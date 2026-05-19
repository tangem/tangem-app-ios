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

    init(sourceTokenItem: TokenItem, receiveTokenItem: TokenItem, provider: ExpressAvailableProvider) {
        title = provider.provider.name
        providerType = provider.provider.type.title
        providerIcon = provider.provider.imageURL

        let formatted = ExpressProviderFormatter().mapToRateSubtitle(
            state: provider.state,
            senderTokenItem: sourceTokenItem,
            destinationTokenItem: receiveTokenItem,
            option: .exchangeRate
        )

        if case .text(let text) = formatted {
            subtitle = text
        }
    }
}
