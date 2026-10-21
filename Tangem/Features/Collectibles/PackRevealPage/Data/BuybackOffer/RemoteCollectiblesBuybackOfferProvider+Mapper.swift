//
//  RemoteCollectiblesBuybackOfferProvider+Mapper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension RemoteCollectiblesBuybackOfferProvider {
    enum Mapper {
        static func mapToOffer(
            _ response: CollectiblesDTO.BuybackAvailabilityResponse
        ) throws -> CollectiblesBuybackOffer? {
            guard response.buybackAvailable else {
                return nil
            }

            guard let cents = response.buybackAmountInCents, cents > 0 else {
                let context = DecodingError.Context(
                    codingPath: [],
                    debugDescription: "An available buyback carries no positive amount"
                )
                throw CollectiblesAPIService.Error.decoding(.dataCorrupted(context))
            }

            return CollectiblesBuybackOffer(amount: cents / Constants.centsScale, expiresAt: response.buybackExpiresAt)
        }
    }
}

// MARK: - Constants

private extension RemoteCollectiblesBuybackOfferProvider.Mapper {
    enum Constants {
        static let centsScale = Decimal(100)
    }
}
