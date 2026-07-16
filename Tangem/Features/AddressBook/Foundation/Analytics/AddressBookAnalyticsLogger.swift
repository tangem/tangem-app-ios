//
//  AddressBookAnalyticsLogger.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol AddressBookAnalyticsLogger {
    func logContactListScreenOpened(source: AddressBookAnalyticsSource, contactsCount: Int)
    func logAddContactTapped(source: AddressBookAnalyticsSource)
    func logContactScreenOpened(contactId: String?)
    func logButtonSaveTo()
    func logContactSaved(contactId: String, mode: AddressBookAnalyticsMode)
    func logSaveErrorShown(contactId: String?, error: Error)
    func logAddressScreenOpened()
    func logAddressInvalid(contactId: String?)
    func logDuplicateNameErrorShown(contactId: String?)
    func logAddressRemoved(contactId: String?)
    func logContactDeleted(contactId: String?)
    func logSendFlowWidgetShown()
    func logContactSelected(contactId: String)
    func logAddressSubstitutedInSend(contactId: String)
    func logSelectAllNetworksTapped(action: AddressBookSelectAllAction)
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
    func logSaveFailure(contactId: String?, error: Error) {
        guard !error.isCancellationError else {
            return
        }

        if let validationError = error as? AddressBookValidationError {
            switch validationError {
            case .addressAlreadySaved:
                return
            case .nameNotUnique:
                logDuplicateNameErrorShown(contactId: contactId)
                return
            default:
                break
            }
        }

        logSaveErrorShown(contactId: contactId, error: error)
    }
}
