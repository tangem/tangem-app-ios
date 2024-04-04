//
//  SendViewNamespaceId.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

enum SendViewNamespaceId: String {
    // Address
    case addressContainer
    case addressTitle
    case addressIcon
    case addressText
    case addressClearButton
    case additionalField

    // Amount
    case amountContainer
    case walletName
    case walletBalance
    case tokenIcon
    case amountCryptoText
    case amountFiatText

    // Fee
    case feeContainer
    case feeTitle
    case feeOption
    case feeAmount
}
