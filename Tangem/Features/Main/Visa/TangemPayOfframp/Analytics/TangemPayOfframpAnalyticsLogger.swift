//
//  TangemPayOfframpAnalyticsLogger.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemPay

protocol TangemPayOfframpAnalyticsLogger {
    func logBankTransferSheetOpened()
    func logToPersonalAccountClicked()
    func logToBusinessAccountClicked()
    func logSavedContactClicked()
    func logSavedContactsSeeAllClicked()

    func logSavedContactsScreenOpened()
    func logSearchBarClicked()
    func logSavedContactOnContactsScreenClicked()

    func logAmountEntered()
    func logCoinSelectorClicked()
    func logCoinSelectionSheetOpened()
    func logCoinInSelectionSheetClicked()
    func logRailSelectorClicked()
    func logRailSelectionSheetOpened()
    func logRailInSelectionSheetClicked()
    func logInsufficientFundsStateShowed()
    func logAmountContinueClicked()

    func logPersonalAccountTypeScreenOpened()
    func logPersonalAccountTypeContinueClicked(isThirdParty: Bool)

    func logRecipientDetailsScreenOpened()
    func logRecipientDetailsFieldFilled(field: TangemPayFormField.ID)
    func logRecipientDetailsContinueClicked()

    func logRecipientBankDetailsScreenOpened()
    func logRecipientBankDetailsFieldFilled(field: TangemPayFormField.ID)
    func logRecipientBankDetailsContinueClicked()

    func logConfirmationScreenOpened()
    func logRecipientDetailsOnConfirmationClicked()
    func logRecipientBankDetailsOnConfirmationClicked()
    func logSendOnConfirmationClicked()

    func logSendErrorScreenOpened()
    func logSendSuccessScreenShowed(rail: TangemPayBankAccountRail?)
}
