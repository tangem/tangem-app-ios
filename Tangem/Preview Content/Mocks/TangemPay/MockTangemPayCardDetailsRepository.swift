//
//  MockTangemPayCardDetailsRepository.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
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

    var cardImageURL: URL? {
        card.mainImageURL
    }

    var cardBackgroundImageURL: URL? {
        card.backgroundImageURL
    }

    var lastFourDigitsPublisher: AnyPublisher<String, Never> {
        card.snapshotPublisher
            .map(\.card.cardNumberEnd)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    var cardNamePublisher: AnyPublisher<String, Never> {
        card.displayNamePublisher
    }

    var isReissuingPublisher: AnyPublisher<Bool, Never> {
        card.isReissuingPublisher
    }

    func updateCardDisplayName(_ name: String) async throws {
        try await card.updateDisplayName(name)
    }

    func revealRequest() async throws -> TangemPayCardDetailsData {
        if ProcessInfo.processInfo.environment["UITEST_TANGEMPAY_CARD_DETAILS_ERROR"] == "1" {
            throw MockError.revealFailed
        }

        return TangemPayCardDetailsData(
            number: "4242 4242 4242 \(lastFourDigits)",
            cardholderName: "JOHNNY SILVERHAND",
            expirationDate: "12/28",
            cvc: "123",
            isPinSet: false
        )
    }
}

private extension MockTangemPayCardDetailsRepository {
    enum MockError: Error {
        case revealFailed
    }
}
