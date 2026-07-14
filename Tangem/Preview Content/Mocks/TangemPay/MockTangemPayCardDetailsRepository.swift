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
    private enum Source {
        case tangemPayAccount(TangemPayAccount)
        case card(TangemPayCard)
    }

    private let source: Source

    init(tangemPayAccount: TangemPayAccount) {
        source = .tangemPayAccount(tangemPayAccount)
    }

    init(card: TangemPayCard) {
        source = .card(card)
    }

    var lastFourDigits: String {
        switch source {
        case .tangemPayAccount(let tangemPayAccount):
            tangemPayAccount.card?.cardNumberEnd ?? "4242"
        case .card(let card):
            card.cardNumberEnd
        }
    }

    var lastFourDigitsPublisher: AnyPublisher<String, Never> {
        switch source {
        case .tangemPayAccount(let tangemPayAccount):
            tangemPayAccount.cardPublisher
                .map { $0?.cardNumberEnd ?? "4242" }
                .removeDuplicates()
                .eraseToAnyPublisher()
        case .card(let card):
            card.snapshotPublisher
                .map(\.card.cardNumberEnd)
                .removeDuplicates()
                .eraseToAnyPublisher()
        }
    }

    var cardNamePublisher: AnyPublisher<String, Never> {
        Just("My Card").eraseToAnyPublisher()
    }

    var isReissuingPublisher: AnyPublisher<Bool, Never> {
        switch source {
        case .tangemPayAccount(let tangemPayAccount):
            tangemPayAccount.isReissuingCardPublisher
        case .card(let card):
            card.isReissuingPublisher
        }
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
