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
        guard let sourceAddress = request.pair.source.address else {
            throw Error.sourceAddressNotFound
        }

        guard let destinationAddress = request.pair.destination.address else {
            throw Error.destinationAddressNotFound
        }

        let feeCurrency = request.pair.source.feeProvider.feeCurrency(
            providerId: providerId
        )

        let source = ExpressSwappableDataItem.SourceWalletInfo(
            address: sourceAddress,
            currency: request.pair.source.currency,
            feeCurrency: feeCurrency
        )

        let destination = ExpressSwappableDataItem.DestinationWalletInfo(
            address: destinationAddress,
            currency: request.pair.destination.currency,
            extraId: request.pair.destination.extraId
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
