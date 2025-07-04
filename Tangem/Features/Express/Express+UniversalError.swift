//
//  Express+UniversalError.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemFoundation

// `Subsystems`:
// `000` - ExpressRepositoryError
// `001` - ExpressFeeProviderError
// `002` - ExpressPendingTransactionRecordError.MigrationError
// `003` - ExpressDestinationServiceError
// `004` - CommonExpressAvailabilityProvider.Error
// `005` -
// `006` -

extension ExpressRepositoryError: UniversalError {
    var errorCode: Int {
        switch self {
        case .availableProvidersDoesNotFound:
            103000000
        }
    }
}

extension ExpressFeeProviderError: UniversalError {
    var errorCode: Int {
        switch self {
        case .feeNotFound:
            103001000
        case .ethereumNetworkProviderNotFound:
            103001001
        }
    }
}

extension ExpressPendingTransactionRecord.MigrationError: UniversalError {
    var errorCode: Int {
        switch self {
        case .networkMismatch:
            103002000
        }
    }
}

extension ExpressDestinationServiceError: UniversalError {
    var errorCode: Int {
        switch self {
        case .destinationNotFound:
            103003000
        }
    }
}

extension CommonExpressAvailabilityProvider.Error: UniversalError {
    var errorCode: Int {
        switch self {
        case .providerNotCreated:
            103004000
        }
    }
}
