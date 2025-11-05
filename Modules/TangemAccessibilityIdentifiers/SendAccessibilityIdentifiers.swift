//
//  SendAccessibilityIdentifiers.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public enum SendAccessibilityIdentifiers {
    /// Main screen elements
    public static let feeSelector = "sendFeeSelector"
    public static let decimalNumberTextField = "sendDecimalNumberTextField"

    /// SendView
    public static let sendViewTitle = "sendViewTitle"
    public static let sendViewNextButton = "sendViewNextButton"
    public static let balanceLabel = "sendBalanceLabel"
    public static let maxAmountButton = "sendMaxAmountButton"

    /// SendAmountCompactView
    public static let sendAmountViewValue = "stakingAmountValue"

    /// ValidatorCompactView
    public static let validatorBlock = "sendValidatorBlock"

    /// SendFeeCompactView
    public static let networkFeeBlock = "sendNetworkFeeBlock"

    /// AddressTextView
    public static let addressTextView = "sendAddressTextView"
    public static let addressClearButton = "sendAddressClearButton"

    /// Notification banners
    public static let invalidAmountBanner = "sendInvalidAmountBanner"
    public static let insufficientAmountToReserveAtDestinationBanner = "sendInsufficientAmountToReserveAtDestinationBanner"
    public static let amountExceedMaximumUTXOBanner = "sendAmountExceedMaximumUTXOBanner"
    public static let customFeeTooLowBanner = "sendCustomFeeTooLowBanner"
    public static let feeWillBeSubtractFromSendingAmountBanner = "sendfeeWillBeSubtractFromSendingAmountBanner"
    public static let customFeeTooHighBanner = "sendCustomFeeTooHighBanner"
    public static let highFeeNotificationBanner = "sendHighFeeNotificationBanner"
    public static let existentialDepositWarningBanner = "sendExistentialDepositWarningBanner"
    public static let remainingAmountIsLessThanRentExemptionBanner = "sendRemainingAmountIsLessThanRentExemptionBanner"
    public static let reduceFeeButton = "sendReduceFeeButton"
    public static let leaveAmountButton = "sendLeaveAmountButton"
    public static let fromWalletButton = "sendFromWalletButton"
}
