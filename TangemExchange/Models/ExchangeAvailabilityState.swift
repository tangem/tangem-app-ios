//
//  ExchangeAvailabilityState.swift
//  TangemExchange
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

public enum ExchangeAvailabilityState {
    case idle
    case loading
    case preview(expected: ExpectedSwappingResult)
    case available(expected: ExpectedSwappingResult, info: ExchangeTransactionDataModel)
    case requiredPermission(expected: ExpectedSwappingResult, info: ExchangeTransactionDataModel)
    case requiredRefresh(occurredError: Error)
}
