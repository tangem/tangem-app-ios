//
//  AccountModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemMacro

@CaseFlagable
enum AccountModel {
    case standard(CryptoAccounts)

    case joint(JointAccounts)

    @available(*, unavailable, message: "This account type is not implemented yet")
    case smart(any SmartAccountModel)

    case tangemPay(any TangemPayAccountModel)

    case polymarket(any PolymarketAccountModel)

    case collectibles(any CollectiblesAccountModel)
}
