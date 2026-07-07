//
//  TangemPayAccessibilityIdentifiers.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public enum TangemPayAccessibilityIdentifiers {
    private static let prefix = "tangemPay"

    // MARK: - Main screen entry

    public static let mainScreenTile = "\(prefix)MainScreenTile"
    public static let getTangemPayBanner = "\(prefix)GetTangemPayBanner"

    // MARK: - Tangem Pay payment account screen

    public static let paymentAccountCardButtonPrefix = "\(prefix)PaymentAccountCardButton"
    public static let paymentAccountCardButton = "\(prefix)PaymentAccountCardButton"
    public static let paymentAccountBalance = "\(prefix)PaymentAccountBalance"
    public static let addFundsButton = "\(prefix)AddFundsButton"
    public static let withdrawButton = "\(prefix)WithdrawButton"

    // MARK: - Add funds flow

    public static let addFundsSheetSwapOption = "\(prefix)AddFundsSheetSwapOption"
    public static let addFundsSheetReceiveOption = "\(prefix)AddFundsSheetReceiveOption"
    public static let addFundsSheetBankTransferOption = "\(prefix)AddFundsSheetBankTransferOption"
    public static let virtualAccountShowDetailsButton = "\(prefix)VirtualAccountShowDetailsButton"
    public static let virtualAccountBankDetailsShareButton = "\(prefix)VirtualAccountBankDetailsShareButton"

    public static func virtualAccountBankDetailValue(_ field: String) -> String {
        "\(prefix)VirtualAccountBankDetailValue_\(field)"
    }

    public static func virtualAccountBankDetailCopyButton(_ field: String) -> String {
        "\(prefix)VirtualAccountBankDetailCopy_\(field)"
    }

    public static func paymentAccountCardButton(cardId: String) -> String {
        "\(paymentAccountCardButtonPrefix)_\(cardId)"
    }

    // MARK: - Withdraw flow

    public static let withdrawNoteSheetPrimaryButton = "\(prefix)WithdrawNoteSheetPrimaryButton"

    // MARK: - Card details (reveal + copy)

    public static let cardDetailsShowButton = "\(prefix)CardDetailsShowButton"
    public static let cardDetailsHideButton = "\(prefix)CardDetailsHideButton"
    public static let cardDetailsNumberValue = "\(prefix)CardDetailsNumberValue"
    public static let cardDetailsExpirationValue = "\(prefix)CardDetailsExpirationValue"
    public static let cardDetailsCvcValue = "\(prefix)CardDetailsCvcValue"
    public static let cardDetailsCopyNumber = "\(prefix)CardDetailsCopyNumber"
    public static let cardDetailsCopyExpiration = "\(prefix)CardDetailsCopyExpiration"
    public static let cardDetailsCopyCvc = "\(prefix)CardDetailsCopyCvc"

    // MARK: - Card management

    public static let changePinRow = "\(prefix)ChangePinRow"
    public static let freezeCardRowStateActive = "\(prefix)FreezeCardRowStateActive"
    public static let freezeCardRowStateFrozen = "\(prefix)FreezeCardRowStateFrozen"
    public static let freezeSheetConfirmButton = "\(prefix)FreezeSheetConfirmButton"
    public static let unfreezeSheetConfirmButton = "\(prefix)UnfreezeSheetConfirmButton"

    // MARK: - PIN setup screen

    public static let pinScreenTitle = "\(prefix)PinScreenTitle"
    public static let pinScreenDescription = "\(prefix)PinScreenDescription"
    public static let pinInputField = "\(prefix)PinInputField"
    public static let pinSubmitButton = "\(prefix)PinSubmitButton"
    public static let pinErrorMessage = "\(prefix)PinErrorMessage"

    // MARK: - PIN success screen

    public static let pinSuccessTitle = "\(prefix)PinSuccessTitle"
    public static let pinSuccessDescription = "\(prefix)PinSuccessDescription"
    public static let pinDoneButton = "\(prefix)PinDoneButton"
}
