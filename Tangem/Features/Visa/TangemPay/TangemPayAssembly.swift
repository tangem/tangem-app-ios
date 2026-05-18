//
//  TangemPayAssembly.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemPay

protocol TangemPayAssembly {
    var customerWalletAddressAndSavedTokensResolver: TangemPayCustomerWalletAddressAndSavedTokensResolver { get }

    func makeCardDetailsRepository(for card: TangemPayCard) -> TangemPayCardDetailsRepository
}
