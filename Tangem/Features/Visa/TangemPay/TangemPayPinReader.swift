//
//  TangemPayPinReader.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol TangemPayPinReader {
    func getPin() async throws -> String
}

struct CommonTangemPayPinReader: TangemPayPinReader {
    private let card: TangemPayCard

    init(card: TangemPayCard) {
        self.card = card
    }

    func getPin() async throws -> String {
        try await card.getPin()
    }
}
