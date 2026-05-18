//
//  CommonTangemPayAssembly.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemPay

final class CommonTangemPayAssembly: TangemPayAssembly {
    let customerWalletAddressAndSavedTokensResolver: TangemPayCustomerWalletAddressAndSavedTokensResolver
        = CommonTangemPayCustomerWalletAddressAndSavedTokensResolver()

    func makeCardDetailsRepository(for card: TangemPayCard) -> TangemPayCardDetailsRepository {
        CommonTangemPayCardDetailsRepository(card: card)
    }
}
