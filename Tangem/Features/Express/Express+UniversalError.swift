//
//  Express+UniversalError.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemFoundation
import TangemExpress

// `Subsystems`:
// `000` - ExpressRepositoryError
// `001` - ExpressFeeLoaderError
// `002` - ExpressPendingTransactionRecordError.MigrationError
// `003` - ExpressDestinationServiceError
// `004` - CommonExpressAvailabilityProvider.Error
// `005` - ExpressTransactionBuilderError
// `006` - ExpressProviderError
// `007` -
// `008` -

extension ExpressRepositoryError: UniversalError {
    var errorCode: Int {
        switch self {
        case .availableProvidersDoesNotFound:
            103000000
        }
    }
}

extension ExpressFeeLoaderError: UniversalError {
    var errorCode: Int {
        switch self {
        case .feeNotFound:
            103001000
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
        case .sourceNotFound:
            103003001
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

extension ExpressDEXTransactionProcessorError: UniversalError {
    var errorCode: Int {
        switch self {
        case .transactionDataForSwapOperationNotFound:
            103005000
        }
    }
}

extension ExpressProviderError: @retroactive UniversalError {
    public var errorCode: Int {
        switch self {
        case .transactionDataNotFound:
            103006000
        case .transactionSizeNotSupported:
            103006001
        case .allowanceProviderNotFound:
            103006002
        }
    }
}
