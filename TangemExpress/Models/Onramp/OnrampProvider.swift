//
//  OnrampProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

public class OnrampProvider {
    public let provider: ExpressProvider
    public let paymentMethod: OnrampPaymentMethod
    public let manager: OnrampProviderManager

    init(
        provider: ExpressProvider,
        paymentMethod: OnrampPaymentMethod,
        manager: OnrampProviderManager
    ) {
        self.provider = provider
        self.paymentMethod = paymentMethod
        self.manager = manager
    }
}
