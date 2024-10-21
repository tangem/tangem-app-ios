//
//  OnrampRepository.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

public protocol OnrampRepository {
    var savedCountry: OnrampCountry? { get }
    var savedPaymentMethod: OnrampPaymentMethod? { get }

    func save(country: OnrampCountry) throws
    func save(paymentMethod: OnrampPaymentMethod) throws
}
