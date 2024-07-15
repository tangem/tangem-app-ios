//
//  SendGeometryEffectNames.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

// MARK: - All names

struct SendGeometryEffectNames: SendAmountViewGeometryEffectNames, StakingValidatorsViewGeometryEffectNames {
    // MARK: - StakingValidatorsViewGeometryEffectNames

    var validatorContainer: String { "ValidatorContainer" }

    // MARK: - SendAmountViewGeometryEffectNames

    var walletName: String { SendViewNamespaceId.walletName.rawValue }
    var walletBalance: String { SendViewNamespaceId.walletBalance.rawValue }
    var amountContainer: String { SendViewNamespaceId.amountContainer.rawValue }
    var tokenIcon: String { SendViewNamespaceId.tokenIcon.rawValue }
    var amountCryptoText: String { SendViewNamespaceId.amountCryptoText.rawValue }
    var amountFiatText: String { SendViewNamespaceId.amountFiatText.rawValue }
}

// MARK: - Amount section

protocol SendAmountViewGeometryEffectNames {
    var walletName: String { get }
    var walletBalance: String { get }
    var amountContainer: String { get }
    var tokenIcon: String { get }
    var amountCryptoText: String { get }
    var amountFiatText: String { get }
}

// MARK: - Validators section

protocol StakingValidatorsViewGeometryEffectNames {
    var validatorContainer: String { get }
}

// MARK: - Summary section

protocol SendSummaryViewGeometryEffectNames {
    var amountContainer: String { get }
    var tokenIcon: String { get }
    var amountCryptoText: String { get }
    var amountFiatText: String { get }
}
