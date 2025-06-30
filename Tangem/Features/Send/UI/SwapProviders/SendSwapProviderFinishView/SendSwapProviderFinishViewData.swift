//
//  SendSwapProviderFinishViewData.swift
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
    @Published var title: String = ""
    @Published var providerType: String = ""

    @Published var subtitle: String = ""
    @Published var providerIcon: URL?

    private let tokenItem: TokenItem
    private let balanceFormatter: BalanceFormatter = .init()
    private var providerSubscription: AnyCancellable?

    init(tokenItem: TokenItem, input: SendSwapProvidersInput) {
        self.tokenItem = tokenItem

        bind(input: input)
    }

    private func bind(input: SendSwapProvidersInput) {
        providerSubscription = input
            .selectedExpressProviderPublisher
            .compactMap { $0 }
            .withWeakCaptureOf(self)
            .sink { $0.updateView(provider: $1) }
    }

    private func updateView(provider: ExpressAvailableProvider) {
        title = provider.provider.name
        providerType = provider.provider.type.title
        providerIcon = provider.provider.imageURL

        Task { @MainActor in
            if let quote = await provider.getState().quote {
                subtitle = formatRate(rate: quote.rate)
            }
        }
    }

    private func formatRate(rate: Decimal) -> String {
        let source = balanceFormatter.formatCryptoBalance(1, currencyCode: tokenItem.currencySymbol)
        return "\(source) \(AppConstants.approximatelyEqualSign) \(rate.formatted())"
    }
}
