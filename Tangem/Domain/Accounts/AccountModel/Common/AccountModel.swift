//
//  AccountModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

enum AccountModel {
    case standard(CryptoAccounts)

    @available(*, unavailable, message: "This account type is not implemented yet")
    case smart(SmartAccountModel)

    @available(*, unavailable, message: "This account type is not implemented yet")
    case visa(VisaAccountModel)
}

// MARK: - Inner types

extension AccountModel {
    // [REDACTED_TODO_COMMENT]
    struct Icon {
        let iconName: String
        let iconColor: String
    }
}
