//
//  SwappingAvailabilityState.swift
//  TangemExchange
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

public enum SwappingAvailabilityState {
    case loading
    case available
    case requiredPermission
    case requiredRefresh(occuredError: Error)
}
