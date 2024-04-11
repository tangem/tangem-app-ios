//
//  SendViewNamespaceId.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

enum SendViewNamespaceId {
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
    case feeOption(feeOption: FeeOption)
    case feeAmount(feeOption: FeeOption)
}

extension SendViewNamespaceId {
    var rawValue: String {
        switch self {
        case .feeOption(let feeOption), .feeAmount(let feeOption):
            return "\(baseValue)-\(feeOption.id)"
        default:
            return baseValue
        }
    }

    private var baseValue: String {
        switch self {
        case .addressContainer:
            "addressContainer"
        case .addressTitle:
            "addressTitle"
        case .addressIcon:
            "addressIcon"
        case .addressText:
            "addressText"
        case .addressClearButton:
            "addressClearButton"
        case .additionalField:
            "additionalField"
        case .amountContainer:
            "amountContainer"
        case .walletName:
            "walletName"
        case .walletBalance:
            "walletBalance"
        case .tokenIcon:
            "tokenIcon"
        case .amountCryptoText:
            "amountCryptoText"
        case .amountFiatText:
            "amountFiatText"
        case .feeContainer:
            "feeContainer"
        case .feeTitle:
            "feeTitle"
        case .feeOption:
            "feeOption"
        case .feeAmount:
            "feeAmount"
        }
    }
}

extension SendViewNamespaceId: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }
}

private extension FeeOption {
    var id: String {
        switch self {
        case .slow:
            "slow"
        case .market:
            "market"
        case .fast:
            "fast"
        case .custom:
            "custom"
        }
    }
}
