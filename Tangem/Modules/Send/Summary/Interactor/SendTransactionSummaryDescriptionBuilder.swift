//
//  SendTransactionSummaryDescriptionBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol SendTransactionSummaryDescriptionBuilder {
    func makeDescription(amount: Decimal, fee: Decimal) -> String?
}
