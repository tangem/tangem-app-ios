//
//  ExpressManagerMapper.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct ExpressManagerMapper {
    func makeExpressSwappableItem(
        request: ExpressManagerSwappingPairRequest,
        providerId: ExpressProvider.Id,
        providerType: ExpressProviderType
    ) -> ExpressSwappableQuoteItem {
        return ExpressSwappableQuoteItem(
            source: request.pair.source.currency,
            destination: request.pair.destination.currency,
            amount: request.amount,
            providerInfo: .init(id: providerId, type: providerType)
        )
    }

    func makeExpressSwappableDataItem(
        request: ExpressManagerSwappingPairRequest,
        providerId: ExpressProvider.Id,
        providerType: ExpressProviderType
    ) throws -> ExpressSwappableDataItem {
        guard let destinationAddress = request.pair.destination.address else {
            throw Error.destinationAddressNotFound
        }

        let source = ExpressSwappableDataItem.SourceWalletInfo(
            address: request.pair.source.address,
            currency: request.pair.source.currency,
            feeCurrency: request.pair.source.feeCurrency
        )

        let destination = ExpressSwappableDataItem.DestinationWalletInfo(
            address: destinationAddress,
            currency: request.pair.destination.currency
        )

        return ExpressSwappableDataItem(
            source: source,
            destination: destination,
            amount: request.amount,
            providerInfo: .init(id: providerId, type: providerType)
        )
    }
}

extension ExpressManagerMapper {
    enum Error: LocalizedError {
        case destinationAddressNotFound

        var errorDescription: String? {
            switch self {
            case .destinationAddressNotFound: "Destination address not found"
            }
        }
    }
}
