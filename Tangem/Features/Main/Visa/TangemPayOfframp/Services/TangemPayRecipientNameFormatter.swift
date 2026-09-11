//
//  TangemPayRecipientNameFormatter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation
import TangemPay

enum TangemPayRecipientNameFormatter {
    enum Style {
        case abbreviated
        case full
    }

    static func name(for bankAccount: TangemPayBankAccountResponse, style: Style) -> String {
        let beneficiary = bankAccount.details.beneficiary

        switch beneficiary.type {
        case .business:
            if let businessName = beneficiary.businessName?.nilIfEmpty {
                return businessName
            }

        case .individual, .none:
            if let firstName = beneficiary.firstName?.nilIfEmpty {
                guard let lastName = beneficiary.lastName?.nilIfEmpty else {
                    return firstName
                }

                switch style {
                case .abbreviated:
                    return "\(firstName) \(lastName.prefix(1))."
                case .full:
                    return "\(firstName) \(lastName)"
                }
            }
        }

        return bankAccount.displayName?.nilIfEmpty ?? bankAccount.details.accountNumber
    }

    static func monogram(for name: String) -> String {
        name.prefix(1).uppercased()
    }
}
