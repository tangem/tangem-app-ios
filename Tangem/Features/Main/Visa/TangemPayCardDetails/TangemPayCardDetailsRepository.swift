//
//  TangemPayCardDetailsRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemVisa
import TangemPay

final class TangemPayCardDetailsRepository {
    let lastFourDigits: String
    private weak var customerService: TangemPayCustomerService?

    init(
        lastFourDigits: String,
        customerService: TangemPayCustomerService
    ) {
        self.lastFourDigits = lastFourDigits
        self.customerService = customerService
    }

    func revealRequest() async throws -> TangemPayCardDetailsData {
        guard let customerService else {
            throw Error.customerServiceNotFound
        }

        let publicKey = try TangemPayUtilities.getRainRSAPublicKey()

        let (secretKey, sessionId) = try RainCryptoUtilities
            .generateSecretKeyAndSessionId(
                publicKey: publicKey
            )

        let cardDetails = try await customerService.getCardDetails(sessionId: sessionId)

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

private extension TangemPayCardDetailsRepository {
    enum Error: LocalizedError {
        case customerServiceNotFound
    }
}
