//
//  TangemPayAccountViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemVisa

struct TangemPayAccountViewModel {
    let card: VisaCustomerInfoResponse.Card
    let balance: TangemPayBalance

    let tapAction: () -> Void
}
