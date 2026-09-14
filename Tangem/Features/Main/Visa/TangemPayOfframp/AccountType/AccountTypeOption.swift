//
//  AccountTypeOption.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemPay

enum AccountTypeOption: CaseIterable, Identifiable {
    case checking
    case savings

    var id: Self { self }

    var title: String {
        switch self {
        case .checking:
            // [REDACTED_TODO_COMMENT]
            "Checking"
        case .savings:
            // [REDACTED_TODO_COMMENT]
            "Saving"
        }
    }
}

// MARK: - Mapping

extension AccountTypeOption {
    var bankAccountType: TangemPayBankAccountType {
        switch self {
        case .checking: .checking
        case .savings: .savings
        }
    }

    init(bankAccountType: TangemPayBankAccountType) {
        switch bankAccountType {
        case .checking: self = .checking
        case .savings: self = .savings
        }
    }
}
