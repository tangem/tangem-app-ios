//
//  TangemPayOfframpAccessibilityIdentifiers.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public enum TangemPayOfframpAccessibilityIdentifiers {
    private static let prefix = "tangemPayOfframp"

    public static let hubWithinPortfolioTile = "\(prefix)Hub_button_withinPortfolio"
    public static let hubPersonalAccountTile = "\(prefix)Hub_button_personalAccount"
    public static let hubBusinessAccountTile = "\(prefix)Hub_button_businessAccount"
    public static let hubRecentTokensEmpty = "\(prefix)Hub_view_recentTokensEmpty"
    public static let hubRecentAccountsEmpty = "\(prefix)Hub_view_recentAccountsEmpty"
    public static let hubRecentAccountsRetry = "\(prefix)Hub_button_recentAccountsRetry"
    public static let hubRecentTokenTile = "\(prefix)Hub_button_recentToken"
    public static let hubRecentAccountTile = "\(prefix)Hub_button_recentAccount"
    public static let hubSeeAllTile = "\(prefix)Hub_button_seeAll"

    public static let recipientsSearchField = "\(prefix)Recipients_textField_search"
    public static let recipientsRow = "\(prefix)Recipients_button_row"
    public static let recipientsSearchEmpty = "\(prefix)Recipients_text_searchEmpty"

    public static let amountField = "\(prefix)Amount_textField_amount"
    public static let amountTokenRow = "\(prefix)Amount_button_token"
    public static let amountContinueButton = "\(prefix)Amount_button_continue"

    public static let tokenSheetRow = "\(prefix)TokenSheet_button_token"

    public static let transferTypeOption = "\(prefix)TransferType_button_option"
    public static let transferTypeContinueButton = "\(prefix)TransferType_button_continue"

    public static let accountTypeOption = "\(prefix)AccountType_button_option"
    public static let accountTypeContinueButton = "\(prefix)AccountType_button_continue"

    public static let formContinueButton = "\(prefix)Form_button_continue"
    public static let formKeyboardDismissButton = "\(prefix)Form_button_keyboardDismiss"

    public static let confirmSection = "\(prefix)Confirm_view_section"
    public static let confirmSendButton = "\(prefix)Confirm_button_send"
}
