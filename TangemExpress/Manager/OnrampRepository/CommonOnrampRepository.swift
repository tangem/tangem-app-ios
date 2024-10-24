//
//  CommonOnrampRepository.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

class CommonOnrampRepository {
    let provider: ExpressAPIProvider

    init(provider: ExpressAPIProvider) {
        self.provider = provider
    }
}

// MARK: - OnrampRepository

// [REDACTED_TODO_COMMENT]
// Add method to save values which user chose
extension CommonOnrampRepository: OnrampRepository {
    var savedCountry: OnrampCountry? { nil }
    var savedPaymentMethod: OnrampPaymentMethod? { nil }

    func save(country: OnrampCountry) throws {}

    func save(paymentMethod: OnrampPaymentMethod) throws {}
}
