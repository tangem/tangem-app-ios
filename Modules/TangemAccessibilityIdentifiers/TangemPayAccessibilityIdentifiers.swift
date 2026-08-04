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
    public static let mainScreenTileBalance = "\(prefix)MainScreenTileBalance"
    public static let getTangemPayBanner = "\(prefix)GetTangemPayBanner"
    public static let getTangemPayBannerOpenButton = "\(prefix)GetTangemPayBannerOpenButton"

    // MARK: - Onboarding (offer) screen

    public static let onboardingGetCardButton = "\(prefix)OnboardingGetCardButton"

    // MARK: - KYC status sheet

    public static let kycStatusSheetPrimaryButton = "\(prefix)KycStatusSheetPrimaryButton"
    public static let kycDeclinedSheetPrimaryButton = "\(prefix)KycDeclinedSheetPrimaryButton"

    // MARK: - Tangem Pay payment account screen

    public static let paymentAccountCardButtonPrefix = "\(prefix)PaymentAccountCardButton"
    public static let paymentAccountCardButton = "\(prefix)PaymentAccountCardButton"
    public static let paymentAccountBalance = "\(prefix)PaymentAccountBalance"
    public static let addFundsButton = "\(prefix)AddFundsButton"
    public static let withdrawButton = "\(prefix)WithdrawButton"
    public static let moreActionsButton = "\(prefix)MoreActionsButton"

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

    // MARK: - Add to Apple/Google Pay guide

    public static let addToApplePayGuideBanner = "\(prefix)AddToApplePayGuideBanner"
    public static let addToApplePayGuideContainer = "\(prefix)AddToApplePayGuideContainer"
    public static let addToApplePayGuideCloseButton = "\(prefix)AddToApplePayGuideCloseButton"

    // MARK: - Card management

    public static let changePinRow = "\(prefix)ChangePinRow"
    public static let freezeCardRowStateActive = "\(prefix)FreezeCardRowStateActive"
    public static let freezeCardRowStateFrozen = "\(prefix)FreezeCardRowStateFrozen"
    public static let freezeSheetConfirmButton = "\(prefix)FreezeSheetConfirmButton"
    public static let unfreezeSheetConfirmButton = "\(prefix)UnfreezeSheetConfirmButton"

    // MARK: - Card rename

    public static let cardNameEditButton = "\(prefix)CardNameEditButton"
    public static let cardNameTextField = "\(prefix)CardNameTextField"
    public static let cardRenameDoneButton = "\(prefix)CardRenameDoneButton"
    public static let cardRenameCloseButton = "\(prefix)CardRenameCloseButton"

    // MARK: - Daily limit

    public static let dailyLimitChangeButton = "\(prefix)DailyLimitChangeButton"
    public static let dailyLimitRowValue = "\(prefix)DailyLimitRowValue"
    public static let dailyLimitAmountField = "\(prefix)DailyLimitAmountField"
    public static let dailyLimitSetButton = "\(prefix)DailyLimitSetButton"
    public static let dailyLimitSuccessTitle = "\(prefix)DailyLimitSuccessTitle"
    public static let dailyLimitDoneButton = "\(prefix)DailyLimitDoneButton"

    public static func dailyLimitPresetButton(_ value: String) -> String {
        "\(prefix)DailyLimitPreset_\(value)"
    }

    // MARK: - Card reissue

    public static let cardManagementMoreButton = "\(prefix)CardManagementMoreButton"
    public static let reissueCardRow = "\(prefix)ReissueCardRow"
    public static let reissueSheetConfirmButton = "\(prefix)ReissueSheetConfirmButton"
    public static let reissueSheetAddFundsButton = "\(prefix)ReissueSheetAddFundsButton"

    // MARK: - Transaction details

    public static let transactionDetailsTitle = "\(prefix)TransactionDetailsTitle"
    public static let transactionDetailsDate = "\(prefix)TransactionDetailsDate"
    public static let transactionDetailsIcon = "\(prefix)TransactionDetailsIcon"
    public static let transactionDetailsAmount = "\(prefix)TransactionDetailsAmount"
    public static let transactionDetailsStatus = "\(prefix)TransactionDetailsStatus"
    public static let transactionDetailsMainButton = "\(prefix)TransactionDetailsMainButton"

    // MARK: - PIN setup screen

    public static let pinScreenTitle = "\(prefix)PinScreenTitle"
    public static let pinScreenDescription = "\(prefix)PinScreenDescription"
    public static let pinInputField = "\(prefix)PinInputField"
    public static let pinSubmitButton = "\(prefix)PinSubmitButton"
    public static let pinErrorMessage = "\(prefix)PinErrorMessage"

    // MARK: - PIN check sheet

    public static let pinCheckTitle = "\(prefix)PinCheckTitle"
    public static let pinCheckLoader = "\(prefix)PinCheckLoader"
    public static let pinCheckValue = "\(prefix)PinCheckValue"
    public static let pinCheckChangeButton = "\(prefix)PinCheckChangeButton"

    // MARK: - PIN success screen

    public static let pinSuccessTitle = "\(prefix)PinSuccessTitle"
    public static let pinSuccessDescription = "\(prefix)PinSuccessDescription"
    public static let pinDoneButton = "\(prefix)PinDoneButton"
}
