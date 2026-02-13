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
        pair: ExpressManagerSwappingPair,
        request: ExpressManagerSwappingPairRequest,
        providerId: ExpressProvider.Id,
        providerType: ExpressProviderType
    ) -> ExpressSwappableQuoteItem {
        return ExpressSwappableQuoteItem(
            source: pair.source.currency,
            destination: pair.destination.currency,
            amount: request.amount,
            providerInfo: .init(id: providerId, type: providerType)
        )
    }

    func makeExpressSwappableDataItem(
        pair: ExpressManagerSwappingPair,
        request: ExpressManagerSwappingPairRequest,
        providerId: ExpressProvider.Id,
        providerType: ExpressProviderType
    ) throws -> ExpressSwappableDataItem {
        guard let sourceAddress = pair.source.address else {
            throw Error.sourceAddressNotFound
        }

        guard let destinationAddress = pair.destination.address else {
            throw Error.destinationAddressNotFound
        }

        let source = ExpressSwappableDataItem.SourceWalletInfo(
            address: sourceAddress,
            currency: pair.source.currency,
            coinCurrency: pair.source.coinCurrency
        )

        let destination = ExpressSwappableDataItem.DestinationWalletInfo(
            address: destinationAddress,
            currency: pair.destination.currency,
            extraId: pair.destination.extraId
        )

        return ExpressSwappableDataItem(
            source: source,
            destination: destination,
            amount: request.amount,
            providerInfo: .init(id: providerId, type: providerType),
            operationType: request.operationType
        )
    }
}

extension ExpressManagerMapper {
    enum Error: LocalizedError {
        case sourceAddressNotFound
        case destinationAddressNotFound

        var errorDescription: String? {
            switch self {
            case .sourceAddressNotFound: "Source address not found"
            case .destinationAddressNotFound: "Destination address not found"
            }
        }
    }
}
