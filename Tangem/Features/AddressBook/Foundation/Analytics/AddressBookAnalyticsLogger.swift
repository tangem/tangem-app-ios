//
//  AddressBookAnalyticsLogger.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol AddressBookAnalyticsLogger {
    func logContactListScreenOpened(walletId: String, source: AddressBookAnalyticsSource, contactsCount: Int)
    func logAddContactTapped(walletId: String, source: AddressBookAnalyticsSource)
    func logContactScreenOpened(walletId: String, contactId: String?)
    func logButtonSaveTo(walletId: String)
    func logContactSaved(walletId: String, contactId: String, mode: AddressBookAnalyticsMode)
    func logSaveErrorShown(walletId: String, contactId: String?, error: Error)
    func logAddressScreenOpened(walletId: String)
    func logAddressInvalid(walletId: String, contactId: String?)
    func logDuplicateNameErrorShown(walletId: String, contactId: String?)
    func logAddressRemoved(walletId: String, contactId: String?)
    func logContactDeleted(walletId: String, contactId: String?)
    func logSendFlowWidgetShown(walletId: String)
    func logContactSelected(walletId: String, contactId: String)
    func logAddressSubstitutedInSend(walletId: String, contactId: String)
    func logSelectAllNetworksTapped(walletId: String, action: AddressBookSelectAllAction)
}

enum AddressBookAnalyticsMode {
    case create
    case edit

    var parameterValue: Analytics.ParameterValue {
        switch self {
        case .create: .addressBookModeCreate
        case .edit: .accountSourceEdit
        }
    }
}

enum AddressBookAnalyticsSource {
    case settings
    case sendFlow
    case sendSuccess

    var parameterValue: Analytics.ParameterValue {
        switch self {
        case .settings: .settings
        case .sendFlow: .addressBookSourceSendFlow
        case .sendSuccess: .addressBookSourceSendSuccess
        }
    }
}

enum AddressBookSelectAllAction {
    case selectAll
    case clearAll

    var parameterValue: Analytics.ParameterValue {
        switch self {
        case .selectAll: .addressBookSelectAll
        case .clearAll: .addressBookClearAll
        }
    }
}

// MARK: - Save failure classification

extension AddressBookAnalyticsLogger {
    /// A user-cancelled card scan is not a failure the user sees, and a duplicate-address save is surfaced as an
    /// inline alert rather than its own event — everything else maps to the generic save-error event.
    func logSaveFailure(walletId: String, contactId: String?, error: Error) {
        guard !error.isCancellationError else {
            return
        }

        if let validationError = error as? AddressBookValidationError {
            switch validationError {
            case .addressAlreadySaved:
                return
            case .nameNotUnique:
                logDuplicateNameErrorShown(walletId: walletId, contactId: contactId)
                return
            default:
                break
            }
        }

        logSaveErrorShown(walletId: walletId, contactId: contactId, error: error)
    }
}
