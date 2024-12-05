//
//  OnrampFinishAnalyticsLogger.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

struct OnrampFinishAnalyticsLogger: SendFinishAnalyticsLogger {
    private let tokenItem: TokenItem
    private weak var onrampProvidersInput: OnrampProvidersInput?

    init(tokenItem: TokenItem, onrampProvidersInput: OnrampProvidersInput) {
        self.tokenItem = tokenItem
        self.onrampProvidersInput = onrampProvidersInput
    }

    func onAppear() {
        guard let provider = onrampProvidersInput?.selectedOnrampProvider?.provider else {
            return
        }

        Analytics.log(event: .onrampBuyingInProgressScreenOpened, params: [
            .token: tokenItem.currencySymbol,
            .provider: provider.name,
        ])
    }
}
