//
//  AccountModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

enum AccountModel {
    case standard(CryptoAccounts)

    @available(*, unavailable, message: "This account type is not implemented yet")
    case smart(any SmartAccountModel)

    case tangemPay(TangemPayAccountModel)
}
