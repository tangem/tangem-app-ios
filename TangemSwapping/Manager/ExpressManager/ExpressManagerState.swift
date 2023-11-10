//
//  ExpressManagerState.swift
//  TangemSwapping
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public enum ExpressManagerState {
    case idle
    
    // Final states
    // Restrictions -> Notifications
    // Will be returned after the quote request
    case restriction(ExpressManagerRestriction)
    
    // Will be returned after the swap request
    case ready(data: ExpressTransactionData)
}
