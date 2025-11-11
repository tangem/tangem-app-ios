//
//  TangemPayCardDetailsViewModelFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemVisa

struct TangemPayCardDetailsViewModelFactory {
    let lastFourDigits: String
    let customerInfoManagementService: any CustomerInfoManagementService

    func makeViewModel() -> TangemPayCardDetailsViewModel {
        TangemPayCardDetailsViewModel(
            lastFourDigits: lastFourDigits,
            customerInfoManagementService: customerInfoManagementService
        )
    }
}
