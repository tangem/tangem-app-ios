//
//  CommonTangemPayCardDetailsRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemVisa
import TangemPay

final class CommonTangemPayCardDetailsRepository: TangemPayCardDetailsRepository {
    var lastFourDigits: String {
        card.cardNumberEnd
    }

    /// `lastFourDigitsPublisher` (added by [REDACTED_INFO] to refresh the UI after reissue) is
    /// sourced from this card's own snapshot in the multi-card model — reissue swaps the
    /// inner BFF snapshot on the same `TangemPayCard` instance, so we observe that.
    var lastFourDigitsPublisher: AnyPublisher<String, Never> {
        card.snapshotPublisher
            .map(\.card.cardNumberEnd)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    var cardNamePublisher: AnyPublisher<String, Never> {
        card.displayNamePublisher
    }

    private let card: TangemPayCard

    init(card: TangemPayCard) {
        self.card = card
    }

    func updateCardDisplayName(_ name: String) async throws {
        try await card.updateDisplayName(name)
    }

    func revealRequest() async throws -> TangemPayCardDetailsData {
        let publicKey = try await RainCryptoUtilities
            .getRainRSAPublicKey(
                for: FeatureStorage.instance.visaAPIType
            )

        let (secretKey, sessionId) = try RainCryptoUtilities
            .generateSecretKeyAndSessionId(
                publicKey: publicKey
            )

        let cardDetails = try await card.customerService.getCardDetails(
            cardId: card.cardId,
            sessionId: sessionId
        )

        let decryptedPan = try RainCryptoUtilities.decryptSecret(
            base64Secret: cardDetails.pan.secret,
            base64Iv: cardDetails.pan.iv,
            secretKey: secretKey
        )

        let decryptedCVV = try RainCryptoUtilities.decryptSecret(
            base64Secret: cardDetails.cvv.secret,
            base64Iv: cardDetails.cvv.iv,
            secretKey: secretKey
        )

        let formattedPan = formatPan(decryptedPan)
        let formattedExpiryDate = formatExpiryDate(
            month: cardDetails.expirationMonth,
            year: cardDetails.expirationYear
        )

        let details = TangemPayCardDetailsData(
            number: formattedPan,
            expirationDate: formattedExpiryDate,
            cvc: decryptedCVV,
            isPinSet: cardDetails.isPinSet
        )
        return details
    }

    private func formatPan(_ pan: String) -> String {
        let cleanPan = pan.replacingOccurrences(of: " ", with: "")
        var formattedPan = ""

        for (index, character) in cleanPan.enumerated() {
            if index > 0, index % 4 == 0 {
                formattedPan += " "
            }
            formattedPan += String(character)
        }

        return formattedPan
    }

    private func formatExpiryDate(month: String, year: String) -> String {
        let monthInt = Int(month) ?? 0
        let formattedMonth = String(format: "%02d", monthInt)
        let formattedYear = String(year).suffix(2)
        return "\(formattedMonth)/\(formattedYear)"
    }
}
