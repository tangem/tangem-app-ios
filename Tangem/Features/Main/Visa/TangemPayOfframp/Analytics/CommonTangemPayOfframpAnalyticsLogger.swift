//
//  CommonTangemPayOfframpAnalyticsLogger.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation
import TangemPay

struct CommonTangemPayOfframpAnalyticsLogger {
    private let userWalletId: UserWalletId

    init(userWalletId: UserWalletId) {
        self.userWalletId = userWalletId
    }
}

// MARK: - TangemPayOfframpAnalyticsLogger

extension CommonTangemPayOfframpAnalyticsLogger: TangemPayOfframpAnalyticsLogger {
    func logBankTransferSheetOpened() {
        log(.visaVAOfframpBankTransferSheetOpened)
    }

    func logToPersonalAccountClicked() {
        log(.visaVAOfframpToPersonalAccountClicked)
    }

    func logToBusinessAccountClicked() {
        log(.visaVAOfframpToBusinessAccountClicked)
    }

    func logSavedContactClicked() {
        log(.visaVAOfframpSavedContactClicked)
    }

    func logSavedContactsSeeAllClicked() {
        log(.visaVAOfframpSavedContactsSeeAllClicked)
    }

    func logSavedContactsScreenOpened() {
        log(.visaVAOfframpSavedContactsScreenOpened)
    }

    func logSearchBarClicked() {
        log(.visaVAOfframpSearchBarClicked)
    }

    func logSavedContactOnContactsScreenClicked() {
        log(.visaVAOfframpSavedContactOnContactsScreenClicked)
    }

    func logAmountEntered() {
        log(.visaVAOfframpAmountEntered)
    }

    func logCoinSelectorClicked() {
        log(.visaVAOfframpCoinSelectorClicked)
    }

    func logCoinSelectionSheetOpened() {
        log(.visaVAOfframpCoinSelectionSheetOpened)
    }

    func logCoinInSelectionSheetClicked() {
        log(.visaVAOfframpCoinInSelectionSheetClicked)
    }

    func logRailSelectorClicked() {
        log(.visaVAOfframpRailSelectorClicked)
    }

    func logRailSelectionSheetOpened() {
        log(.visaVAOfframpRailSelectionSheetOpened)
    }

    func logRailInSelectionSheetClicked() {
        log(.visaVAOfframpRailInSelectionSheetClicked)
    }

    func logInsufficientFundsStateShowed() {
        log(.visaVAOfframpInsufficientFundsStateShowed)
    }

    func logAmountContinueClicked() {
        log(.visaVAOfframpAmountContinueClicked)
    }

    func logPersonalAccountTypeScreenOpened() {
        log(.visaVAOfframpPersonalAccountTypeScreenOpened)
    }

    func logPersonalAccountTypeContinueClicked(isThirdParty: Bool) {
        let type: TangemPayOfframpAnalyticsValue = isThirdParty ? .thirdParty : .firstParty

        log(.visaVAOfframpPersonalAccountTypeContinueClicked, params: [.type: type.rawValue])
    }

    func logRecipientDetailsScreenOpened() {
        log(.visaVAOfframpRecipientDetailsScreenOpened)
    }

    func logRecipientDetailsFieldFilled(field: TangemPayFormField.ID) {
        log(.visaVAOfframpRecipientDetailsFieldFilled, params: [.field: field.analyticsName])
    }

    func logRecipientDetailsContinueClicked() {
        log(.visaVAOfframpRecipientDetailsContinueClicked)
    }

    func logRecipientBankDetailsScreenOpened() {
        log(.visaVAOfframpRecipientBankDetailsScreenOpened)
    }

    func logRecipientBankDetailsFieldFilled(field: TangemPayFormField.ID) {
        log(.visaVAOfframpRecipientBankDetailsFieldFilled, params: [.field: field.analyticsName])
    }

    func logRecipientBankDetailsContinueClicked() {
        log(.visaVAOfframpRecipientBankDetailsContinueClicked)
    }

    func logConfirmationScreenOpened() {
        log(.visaVAOfframpConfirmationScreenOpened)
    }

    func logRecipientDetailsOnConfirmationClicked() {
        log(.visaVAOfframpRecipientDetailsOnConfirmationClicked)
    }

    func logRecipientBankDetailsOnConfirmationClicked() {
        log(.visaVAOfframpRecipientBankDetailsOnConfirmationClicked)
    }

    func logSendOnConfirmationClicked() {
        log(.visaVAOfframpSendOnConfirmationClicked)
    }

    func logSendErrorScreenOpened() {
        log(.visaVAOfframpSendErrorScreenOpened)
    }

    func logSendSuccessScreenShowed(rail: TangemPayBankAccountRail?) {
        guard let rail else {
            log(.visaVAOfframpSendSuccessScreenShowed)
            return
        }

        log(.visaVAOfframpSendSuccessScreenShowed, params: [.type: rail.analyticsName])
    }
}

// MARK: - Logging

private extension CommonTangemPayOfframpAnalyticsLogger {
    func log(_ event: Analytics.Event, params: [Analytics.ParameterKey: String] = [:]) {
        Analytics.log(event: event, params: params, contextParams: .userWallet(userWalletId))
    }
}

// MARK: - Parameter values

private enum TangemPayOfframpAnalyticsValue: String {
    case firstParty = "1st party"
    case thirdParty = "3rd party"
}

private extension TangemPayBankAccountRail {
    var analyticsName: String {
        switch self {
        case .ach: "ACH"
        case .wire: "Wire"
        default: rawValue
        }
    }
}
