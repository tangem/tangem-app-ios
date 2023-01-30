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
    case loading(_ type: ExchangeAvailabilityLoadingType)
    case preview(_ model: PreviewSwappingDataModel)
    case available(_ model: SwappingResultDataModel, info: ExchangeTransactionDataModel)
    case requiredRefresh(occurredError: Error)
}

public enum ExchangeAvailabilityLoadingType {
    case full
    case autoupdate
}
