//
//  MockTangemPayCardDetailsRepository.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemPay

/// Returns hardcoded card details without touching the network or crypto.
final class MockTangemPayCardDetailsRepository: TangemPayCardDetailsRepository {
    let lastFourDigits: String = "4242"

    var lastFourDigitsPublisher: AnyPublisher<String, Never> {
        Just(lastFourDigits).eraseToAnyPublisher()
    }

    var cardNamePublisher: AnyPublisher<String, Never> {
        Just("My Card").eraseToAnyPublisher()
    }

    var isReissuingPublisher: AnyPublisher<Bool, Never> {
        Just(false).eraseToAnyPublisher()
    }

    func updateCardDisplayName(_ name: String) async throws {}

    func revealRequest() async throws -> TangemPayCardDetailsData {
        TangemPayCardDetailsData(
            number: "4242 4242 4242 4242",
            expirationDate: "12/28",
            cvc: "123",
            isPinSet: false
        )
    }
}
