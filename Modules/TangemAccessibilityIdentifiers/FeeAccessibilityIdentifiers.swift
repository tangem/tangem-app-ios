//
//  FeeAccessibilityIdentifiers.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public enum FeeAccessibilityIdentifiers {
    // Fee options
    public static let suggestedFeeOption = "feeOptionSuggested"
    public static let slowFeeOption = "feeOptionSlow"
    public static let marketFeeOption = "feeOptionMarket"
    public static let fastFeeOption = "feeOptionFast"
    public static let customFeeOption = "feeOptionCustom"

    /// Fee selector title
    public static let feeSelectorChooseSpeedTitle = "feeSelectorChooseSpeedTitle"
    public static let feeSelectorNetworkFeeTitle = "feeSelectorNetworkFeeTitle"
    public static let feeSelectorChooseTokenTitle = "feeSelectorChooseTokenTitle"

    /// Token options
    public static let suggestedFeeCurrency = "feeCurrencySuggested"

    public static func feeCurrencyOption(symbol: String) -> String {
        "feeCurrencyOption_\(symbol)"
    }

    /// Fee selector summary fee row
    public static let feeSelectorSummaryFee = "feeSelectorSummaryFee"

    /// Highlighted "Not enough funds" subtitle on the fee selector summary fee row
    public static let feeSelectorInsufficientFundsError = "feeSelectorInsufficientFundsError"

    /// Fee selector actions
    public static let feeSelectorDoneButton = "feeSelectorDoneButton"
    public static let feeSelectorApplyButton = "feeSelectorApplyButton"

    /// Custom fee fields
    public static let customFeeMaxFeeField = "customFeeMaxFeeField"
    public static let customFeeMaxFeeFiatValue = "customFeeMaxFeeFiatValue"
    public static let customFeeSatoshiPerByteField = "customFeeSatoshiPerByteField"
    public static let customFeeNonceField = "customFeeNonceField"
    public static let customFeeTotalAmountField = "customFeeTotalAmountField"
}
