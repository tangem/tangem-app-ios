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

    /// Fee selector actions
    public static let feeSelectorDoneButton = "feeSelectorDoneButton"

    /// Custom fee fields
    public static let customFeeMaxFeeField = "customFeeMaxFeeField"
    public static let customFeeMaxFeeFiatValue = "customFeeMaxFeeFiatValue"
    public static let customFeeSatoshiPerByteField = "customFeeSatoshiPerByteField"
    public static let customFeeNonceField = "customFeeNonceField"
    public static let customFeeTotalAmountField = "customFeeTotalAmountField"
}
