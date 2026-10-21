//
//  TransactionDetailsAmountTextBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation

enum TransactionDetailsAmountTextBuilder {
    static func build(_ amount: String?, symbol: String?, sign: String? = nil) -> String? {
        guard let amount = amount?.trimmed().nilIfEmpty else {
            return nil
        }

        var text = amount

        if let symbol = symbol?.trimmed().nilIfEmpty {
            text += String.unbreakableSpace + symbol
        }

        if let sign = sign?.trimmed().nilIfEmpty {
            text = sign + AppConstants.thinSpace + text
        }

        return text
    }
}
