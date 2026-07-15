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
    public static let scanQRButton = "sendScanQRButton"

    /// SendAmountCompactView
    public static let sendAmountViewValue = "stakingAmountValue"

    /// SendDecimalNumberTextField currency symbol (prefix/suffix)
    public static let currencySymbol = "sendCurrencySymbol"

    /// Alternative amount displays (crypto/fiat conversion)
    public static let alternativeCryptoAmount = "sendAlternativeCryptoAmount"
    public static let alternativeFiatAmount = "sendAlternativeFiatAmount"
    public static let currencyToggleButton = "sendCurrencyToggleButton"

    /// ValidatorCompactView
    public static let validatorBlock = "sendValidatorBlock"

    /// SendFeeCompactView
    public static let networkFeeBlock = "sendNetworkFeeBlock"
    public static let networkFeeAmount = "sendNetworkFeeAmount"
    public static let networkFeeCurrencySymbol = "sendNetworkFeeCurrencySymbol"
    public static let networkFeeUnreachableBanner = "sendNetworkFeeUnreachableBanner"

    /// AddressTextView
    public static let addressTextView = "sendAddressTextView"
    public static let addressClearButton = "sendAddressClearButton"
    public static let addressFieldTitle = "sendAddressFieldTitle"
    public static let addressPasteButton = "sendAddressPasteButton"
    public static let addressNetworkWarning = "sendAddressNetworkWarning"
    public static let addressResolvedAddress = "sendAddressResolvedAddress"

    /// AdditionalField (Memo/DestinationTag)
    public static let additionalFieldTextField = "sendAdditionalFieldTextField"
    public static let additionalFieldClearButton = "sendAdditionalFieldClearButton"
    public static let additionalFieldPasteButton = "sendAdditionalFieldPasteButton"
    public static let invalidMemoBanner = "sendInvalidMemoBanner"

    /// Suggested Destination (Wallet History)
    public static let suggestedDestinationHeader = "sendSuggestedDestinationHeader"
    public static let suggestedDestinationMyWalletsBlock = "sendSuggestedDestinationMyWalletsBlock"
    public static let suggestedDestinationWalletCell = "sendSuggestedDestinationWalletCell"
    public static let suggestedDestinationTransactionCell = "sendSuggestedDestinationTransactionCell"

    public static func suggestedDestinationWalletCell(index: Int) -> String {
        "sendSuggestedDestinationWalletCell_\(index)"
    }

    public static func suggestedDestinationTransactionCell(index: Int) -> String {
        "sendSuggestedDestinationTransactionCell_\(index)"
    }

    /// Notification banners
    public static let invalidAmountBanner = "sendInvalidAmountBanner"
    public static let totalExceedsBalanceBanner = "sendTotalExceedsBalanceBanner"
    public static let insufficientAmountToReserveAtDestinationBanner = "sendInsufficientAmountToReserveAtDestinationBanner"
    public static let amountExceedMaximumUTXOBanner = "sendAmountExceedMaximumUTXOBanner"
    public static let customFeeTooLowBanner = "sendCustomFeeTooLowBanner"
    public static let feeWillBeSubtractFromSendingAmountBanner = "sendfeeWillBeSubtractFromSendingAmountBanner"
    public static let insufficientBalanceForFeeBanner = "sendInsufficientBalanceForFeeBanner"
    public static let customFeeTooHighBanner = "sendCustomFeeTooHighBanner"
    public static let highFeeNotificationBanner = "sendHighFeeNotificationBanner"
    public static let existentialDepositWarningBanner = "sendExistentialDepositWarningBanner"
    public static let remainingAmountIsLessThanRentExemptionBanner = "sendRemainingAmountIsLessThanRentExemptionBanner"
    public static let reduceFeeButton = "sendReduceFeeButton"
    public static let leaveAmountButton = "sendLeaveAmountButton"
    public static let fromWalletButton = "sendFromWalletButton"

    /// Send via Swap
    public static let convertToAnotherTokenButton = "sendConvertToAnotherTokenButton"
    public static let receiveTokenBlock = "sendReceiveTokenBlock"
    public static let receiveDecimalNumberTextField = "sendReceiveDecimalNumberTextField"
    public static let removeConvertButton = "sendRemoveConvertButton"
    public static let networkSelectorErrorTitle = "sendNetworkSelectorErrorTitle"
    public static let networkSelectorErrorSubtitle = "sendNetworkSelectorErrorSubtitle"
    public static let networkSelectorGotItButton = "sendNetworkSelectorGotItButton"
    public static let networkSelectorSwapRequiredTitle = "sendNetworkSelectorSwapRequiredTitle"
    public static let networkSelectorSwapTokenButton = "sendNetworkSelectorSwapTokenButton"

    public static func receiveTokenListItem(name: String) -> String {
        "sendReceiveTokenListItem_\(name)"
    }

    /// Swap Provider (compact view on summary)
    public static let swapProviderBlock = "sendSwapProviderBlock"
    public static let swapProviderName = "sendSwapProviderName"

    /// Swap Provider Selector
    public static let swapProviderBestRateBadge = "sendSwapProviderBestRateBadge"
    public static let swapProviderBestDexRateBadge = "sendSwapProviderBestDexRateBadge"

    public static func swapProviderSelectorRow(name: String) -> String {
        "sendSwapProviderSelectorRow_\(name)"
    }

    public static func swapProviderSelectorApproveButton(name: String) -> String {
        "sendSwapProviderSelectorApproveButton_\(name)"
    }

    /// Token search in receive token list
    public static let receiveTokenSearchBar = "sendReceiveTokenSearchBar"

    /// Send Summary (Confirm) screen
    public static let summaryDestinationBlock = "sendSummaryDestinationBlock"

    /// Send Finish Screen
    public static let finishHeader = "sendFinishHeader"
    public static let finishTransactionTime = "sendFinishTransactionTime"
    public static let finishExploreButton = "sendFinishExploreButton"
    public static let finishShareButton = "sendFinishShareButton"
}
