//
//  WCRequestDetailsViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import UIKit

struct WCRequestDetailsViewModel {
    let requestDetails: [WCTransactionDetailsSection]

    init(input: WCRequestDetailsInput) {
        requestDetails = input.builder.makeRequestDetails()
    }
}
