//
//  SwappingAvailabilityState.swift
//  TangemSwapping
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

public enum SwappingAvailabilityState {
    case idle
    case loading(_ type: SwappingManagerRefreshType)
    case preview(_ model: SwappingPreviewData)
    case available(_ model: SwappingResultData, data: SwappingTransactionData)
    case requiredRefresh(occurredError: Error)
}
