//
//  MainQRScanTokenSelectorAvailabilityFilter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk

enum MainQRScanTokenSelectorAvailabilityFilter {
    case tokenItems(Set<TokenItem>)
    case blockchains(Set<Blockchain>)
}
