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
    public static let mainScreenTileSubtitle = "\(prefix)MainScreenTileSubtitle"
    public static let mainScreenTileCurrency = "\(prefix)MainScreenTileCurrency"
    public static let mainScreenTileCachedIcon = "\(prefix)MainScreenTileCachedIcon"
    public static let getTangemPayBanner = "\(prefix)GetTangemPayBanner"
    public static let getTangemPayBannerOpenButton = "\(prefix)GetTangemPayBannerOpenButton"

    // MARK: - Stale state notifications

    public static let sessionExpiredNotification = "\(prefix)SessionExpiredNotification"
    public static let serviceUnavailableNotification = "\(prefix)ServiceUnavailableNotification"
    public static let cardDeactivatedNotification = "\(prefix)CardDeactivatedNotification"

    // MARK: - Onboarding (offer) screen

    public static let onboardingGetCardButton = "\(prefix)OnboardingGetCardButton"

    // MARK: - Mobile onboarding screen

    public static let mobileOnboardingTitle = "\(prefix)MobileOnboardingTitle"
    public static let mobileOnboardingGetCardButton = "\(prefix)MobileOnboardingGetCardButton"

    // MARK: - KYC status sheet

    public static let kycStatusSheetPrimaryButton = "\(prefix)KycStatusSheetPrimaryButton"
    public static let kycDeclinedSheetPrimaryButton = "\(prefix)KycDeclinedSheetPrimaryButton"

    // MARK: - Tangem Pay payment account screen

    public static let paymentAccountCardButtonPrefix = "\(prefix)PaymentAccountCardButton"
    public static let paymentAccountCardButton = "\(prefix)PaymentAccountCardButton"
    public static let paymentAccountAddCardButton = "\(prefix)PaymentAccountAddCardButton"
    public static let paymentAccountToolbarTitle = "\(prefix)PaymentAccountToolbarTitle"
    public static let paymentAccountToolbarSubtitle = "\(prefix)PaymentAccountToolbarSubtitle"
    public static let paymentAccountBalance = "\(prefix)PaymentAccountBalance"
    public static let addFundsButton = "\(prefix)AddFundsButton"
    public static let withdrawButton = "\(prefix)WithdrawButton"
    public static let moreActionsButton = "\(prefix)MoreActionsButton"
    public static let termsAndLimitsMenuItem = "\(prefix)TermsAndLimitsMenuItem"
    public static let paySupportMenuItem = "\(prefix)PaySupportMenuItem"
    public static let removeAccountMenuItem = "\(prefix)RemoveAccountMenuItem"

    // MARK: - Add funds flow

    public static let addFundsSheetSwapOption = "\(prefix)AddFundsSheetSwapOption"
    public static let addFundsSheetReceiveOption = "\(prefix)AddFundsSheetReceiveOption"
    public static let addFundsSheetBankTransferOption = "\(prefix)AddFundsSheetBankTransferOption"
    public static let addFundsSheetCloseButton = "\(prefix)AddFundsSheetCloseButton"
    public static let virtualAccountShowDetailsButton = "\(prefix)VirtualAccountShowDetailsButton"
    public static let virtualAccountBankDetailsShareButton = "\(prefix)VirtualAccountBankDetailsShareButton"
    public static let virtualAccountFeeErrorBanner = "\(prefix)VirtualAccountFeeErrorBanner"
    public static let virtualAccountSuccessTitle = "\(prefix)VirtualAccountSuccessTitle"
    public static let virtualAccountSuccessCloseButton = "\(prefix)VirtualAccountSuccessCloseButton"
    public static let virtualAccountDepositLimitTitle = "\(prefix)VirtualAccountDepositLimitTitle"
    public static let virtualAccountDepositLimitSubtitle = "\(prefix)VirtualAccountDepositLimitSubtitle"
    public static let virtualAccountBankDetailsErrorRetryButton = "\(prefix)VirtualAccountBankDetailsErrorRetryButton"

    public static func virtualAccountFeeTitle(_ fee: VirtualAccountFee) -> String {
        "\(prefix)VirtualAccountFeeTitle_\(fee.rawValue)"
    }

    public static func virtualAccountFeeValue(_ fee: VirtualAccountFee) -> String {
        "\(prefix)VirtualAccountFeeValue_\(fee.rawValue)"
    }

    public static func virtualAccountBankDetailValue(_ field: String) -> String {
        "\(prefix)VirtualAccountBankDetailValue_\(field)"
    }

    public static func virtualAccountBankDetailCopyButton(_ field: String) -> String {
        "\(prefix)VirtualAccountBankDetailCopy_\(field)"
    }

    public static func paymentAccountCardButton(cardId: String) -> String {
        "\(paymentAccountCardButtonPrefix)_\(cardId)"
    }

    // MARK: - Multichain deposit: choose network sheet

    public static let chooseNetworkSheetCloseButton = "\(prefix)ChooseNetworkSheetCloseButton"
    public static let chooseNetworkSheetFastOptionsTitle = "\(prefix)ChooseNetworkSheetFastOptionsTitle"
    public static let chooseNetworkSheetOtherOptionsTitle = "\(prefix)ChooseNetworkSheetOtherOptionsTitle"
    public static let chooseNetworkSheetRowPrefix = "\(prefix)ChooseNetworkSheetRow"

    public static func chooseNetworkSheetRow(chainId: Int) -> String {
        "\(chooseNetworkSheetRowPrefix)_\(chainId)"
    }

    // MARK: - Multichain deposit: other networks sheet

    public static let otherNetworksSheetTitle = "\(prefix)OtherNetworksSheetTitle"
    public static let otherNetworksSheetSubtitle = "\(prefix)OtherNetworksSheetSubtitle"
    public static let otherNetworksSheetCloseButton = "\(prefix)OtherNetworksSheetCloseButton"

    // MARK: - Multichain deposit: receive sheet

    public static let multichainReceiveSheetWarningTitle = "\(prefix)MultichainReceiveSheetWarningTitle"
    public static let multichainReceiveSheetWarningDescription = "\(prefix)MultichainReceiveSheetWarningDescription"
    public static let multichainReceiveSheetHeading = "\(prefix)MultichainReceiveSheetHeading"
    public static let multichainReceiveSheetAddress = "\(prefix)MultichainReceiveSheetAddress"
    public static let multichainReceiveSheetCopyButton = "\(prefix)MultichainReceiveSheetCopyButton"
    public static let multichainReceiveSheetShowQRButton = "\(prefix)MultichainReceiveSheetShowQRButton"
    public static let multichainReceiveSheetShareButton = "\(prefix)MultichainReceiveSheetShareButton"
    public static let multichainReceiveSheetTokenIconPrefix = "\(prefix)MultichainReceiveSheetTokenIcon"

    public static func multichainReceiveSheetTokenIcon(symbol: String) -> String {
        "\(multichainReceiveSheetTokenIconPrefix)_\(symbol)"
    }

    // MARK: - Withdraw flow

    public static let withdrawNoteSheetPrimaryButton = "\(prefix)WithdrawNoteSheetPrimaryButton"

    // MARK: - Card details (reveal + copy)

    public static let cardDetailsShowButton = "\(prefix)CardDetailsShowButton"
    public static let cardDetailsHideButton = "\(prefix)CardDetailsHideButton"
    public static let cardDetailsNumberValue = "\(prefix)CardDetailsNumberValue"
    public static let cardDetailsCardholderNameValue = "\(prefix)CardDetailsCardholderNameValue"
    public static let cardDetailsExpirationValue = "\(prefix)CardDetailsExpirationValue"
    public static let cardDetailsCvcValue = "\(prefix)CardDetailsCvcValue"
    public static let cardDetailsCopyNumber = "\(prefix)CardDetailsCopyNumber"
    public static let cardDetailsCopyCardholderName = "\(prefix)CardDetailsCopyCardholderName"
    public static let cardDetailsCopyExpiration = "\(prefix)CardDetailsCopyExpiration"
    public static let cardDetailsCopyCvc = "\(prefix)CardDetailsCopyCvc"

    // MARK: - Add to Apple/Google Pay guide

    public static let addToApplePayGuideBanner = "\(prefix)AddToApplePayGuideBanner"
    public static let addToApplePayGuideBannerCloseButton = "\(prefix)AddToApplePayGuideBannerCloseButton"
    public static let addToApplePayGuideContainer = "\(prefix)AddToApplePayGuideContainer"
    public static let addToApplePayGuideCloseButton = "\(prefix)AddToApplePayGuideCloseButton"

    // MARK: - Card management

    public static let changePinRow = "\(prefix)ChangePinRow"
    public static let freezeCardRowStateActive = "\(prefix)FreezeCardRowStateActive"
    public static let freezeCardRowStateFrozen = "\(prefix)FreezeCardRowStateFrozen"
    public static let freezeSheetConfirmButton = "\(prefix)FreezeSheetConfirmButton"
    public static let unfreezeSheetConfirmButton = "\(prefix)UnfreezeSheetConfirmButton"
    public static let closeCardSheetConfirmButton = "\(prefix)CloseCardSheetConfirmButton"

    // MARK: - Popup sheet

    public static let popupIcon = "\(prefix)PopupIcon"
    public static let popupCloseButton = "\(prefix)PopupCloseButton"
    public static let popupSecondaryButton = "\(prefix)PopupSecondaryButton"

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

    // MARK: - Additional card issue

    public static let issueAdditionalCardSheetConfirmButton = "\(prefix)IssueAdditionalCardSheetConfirmButton"
    public static let orderCardTypeSelectButton = "\(prefix)OrderCardTypeSelectButton"
    public static let paymentAccountIssuingCardButton = "\(prefix)PaymentAccountIssuingCardButton"
    public static let issuingCardBanner = "\(prefix)IssuingCardBanner"
    public static let cardIssuingMessage = "\(prefix)CardIssuingMessage"

    // MARK: - Transaction details

    public static let transactionDetailsTitle = "\(prefix)TransactionDetailsTitle"
    public static let transactionDetailsDate = "\(prefix)TransactionDetailsDate"
    public static let transactionDetailsIcon = "\(prefix)TransactionDetailsIcon"
    public static let transactionDetailsAmount = "\(prefix)TransactionDetailsAmount"
    public static let transactionDetailsAmountSubtitle = "\(prefix)TransactionDetailsAmountSubtitle"
    public static let transactionDetailsStatus = "\(prefix)TransactionDetailsStatus"
    public static let transactionDetailsStatusReason = "\(prefix)TransactionDetailsStatusReason"
    public static let transactionDetailsStatusIcon = "\(prefix)TransactionDetailsStatusIcon"
    public static let transactionDetailsCategoryRow = "\(prefix)TransactionDetailsCategoryRow"
    public static let transactionDetailsMccRow = "\(prefix)TransactionDetailsMccRow"
    public static let transactionDetailsCardRow = "\(prefix)TransactionDetailsCardRow"
    public static let transactionDetailsCardRowRetryButton = "\(prefix)TransactionDetailsCardRowRetryButton"
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

    // MARK: - Tariff plans

    public static let currentPlanMenuItem = "\(prefix)CurrentPlanMenuItem"
    public static let paymentAccountInactiveBadge = "\(prefix)PaymentAccountInactiveBadge"
    public static let awaitingDepositBanner = "\(prefix)AwaitingDepositBanner"

    public static let currentPlanName = "\(prefix)CurrentPlanName"
    public static let currentPlanChangeButton = "\(prefix)CurrentPlanChangeButton"
    public static let currentPlanFullTermsButton = "\(prefix)CurrentPlanFullTermsButton"
    public static let currentPlanAwaitingDepositBanner = "\(prefix)CurrentPlanAwaitingDepositBanner"
    public static let currentPlanDowngradeBanner = "\(prefix)CurrentPlanDowngradeBanner"
    public static let currentPlanFeeChargedBanner = "\(prefix)CurrentPlanFeeChargedBanner"

    public static let selectPlanName = "\(prefix)SelectPlanName"
    public static let selectPlanCarousel = "\(prefix)SelectPlanCarousel"
    public static let selectPlanSelectButton = "\(prefix)SelectPlanSelectButton"
    public static let selectPlanCompareButton = "\(prefix)SelectPlanCompareButton"

    public static let confirmPlanTitle = "\(prefix)ConfirmPlanTitle"
    public static let confirmPlanPrimaryButton = "\(prefix)ConfirmPlanPrimaryButton"

    public static let cardsLimitReachedConfirmButton = "\(prefix)CardsLimitReachedConfirmButton"
    public static let maximumCardsIssuedConfirmButton = "\(prefix)MaximumCardsIssuedConfirmButton"
    public static let stayOnPlusConfirmButton = "\(prefix)StayOnPlusConfirmButton"

    public static func currentPlanSection(_ title: String) -> String {
        "\(prefix)CurrentPlanSection_\(title)"
    }

    public static func currentPlanRow(_ title: String) -> String {
        "\(prefix)CurrentPlanRow_\(title)"
    }

    public static func comparePlansSection(_ title: String) -> String {
        "\(prefix)ComparePlansSection_\(title)"
    }

    public static func comparePlansRow(_ planName: String) -> String {
        "\(prefix)ComparePlansRow_\(planName)"
    }

    // MARK: - Cashback on payment account screen

    public static let cashbackBannerTitle = "\(prefix)CashbackBannerTitle"
    public static let cashbackBannerSubtitle = "\(prefix)CashbackBannerSubtitle"
    public static let cashbackMenuItem = "\(prefix)CashbackMenuItem"
    public static let cashbackDeactivatedBanner = "\(prefix)CashbackDeactivatedBanner"

    // MARK: - Cashback screen

    public static let cashbackDetailCloseButton = "\(prefix)CashbackDetailCloseButton"
    public static let cashbackDetailHeaderTitle = "\(prefix)CashbackDetailHeaderTitle"
    public static let cashbackDetailHeaderSubtitle = "\(prefix)CashbackDetailHeaderSubtitle"
    public static let cashbackDetailInfoBanner = "\(prefix)CashbackDetailInfoBanner"
    public static let cashbackDetailRateCard = "\(prefix)CashbackDetailRateCard"
    public static let cashbackDetailAccrualsCard = "\(prefix)CashbackDetailAccrualsCard"
    public static let cashbackDetailReloadButton = "\(prefix)CashbackDetailReloadButton"
    public static let cashbackDetailErrorTitle = "\(prefix)CashbackDetailErrorTitle"
    public static let cashbackChartTotal = "\(prefix)CashbackChartTotal"
    public static let cashbackChartMonthPrefix = "\(prefix)CashbackChartMonth"
    private static let cashbackChartValuePrefix = "\(prefix)CashbackChartValue"
    public static let cashbackAdditionalSectionTitle = "\(prefix)CashbackAdditionalSectionTitle"

    public static func cashbackChartMonth(_ month: String) -> String {
        "\(cashbackChartMonthPrefix)_\(month)"
    }

    public static func cashbackChartValue(_ month: String) -> String {
        "\(cashbackChartValuePrefix)_\(month)"
    }
}

public extension TangemPayAccessibilityIdentifiers {
    enum VirtualAccountFee: String {
        case ach
        case fedwire
    }
}
