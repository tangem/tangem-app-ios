//
//  MockTangemPayCardDetailsRepository.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemVisa
import TangemPay

final class MockTangemPayCardDetailsRepository: TangemPayCardDetailsRepository {
    private let card: TangemPayCard

    init(card: TangemPayCard) {
        self.card = card
    }

    var lastFourDigits: String {
        card.cardNumberEnd
    }

    var lastFourDigitsPublisher: AnyPublisher<String, Never> {
        card.snapshotPublisher
            .map(\.card.cardNumberEnd)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    var cardNamePublisher: AnyPublisher<String, Never> {
        Just("My Card").eraseToAnyPublisher()
    }

    var isReissuingPublisher: AnyPublisher<Bool, Never> {
        card.isReissuingPublisher
    }

    func updateCardDisplayName(_ name: String) async throws {}

    func revealRequest() async throws -> TangemPayCardDetailsData {
        TangemPayCardDetailsData(
            number: "4242 4242 4242 \(lastFourDigits)",
            expirationDate: "12/28",
            cvc: "123",
            isPinSet: false
        )
    }
}
