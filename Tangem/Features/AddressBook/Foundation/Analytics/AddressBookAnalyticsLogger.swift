//
//  AddressBookAnalyticsLogger.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

protocol AddressBookAnalyticsLogger {
    func logContactListScreenOpened(userWalletId: UserWalletId?, source: AddressBookAnalyticsSource, contactsCount: Int)
    func logAddContactTapped(userWalletId: UserWalletId?, source: AddressBookAnalyticsSource)
    func logContactScreenOpened(userWalletId: UserWalletId?, contactId: String?)
    func logButtonSaveTo()
    func logContactSaved(userWalletId: UserWalletId?, contactId: String, mode: AddressBookAnalyticsMode)
    func logSaveErrorShown(userWalletId: UserWalletId?, contactId: String?, error: Error)
    func logAddressScreenOpened()
    func logAddressInvalid(userWalletId: UserWalletId?, contactId: String?)
    func logDuplicateNameErrorShown(userWalletId: UserWalletId?, contactId: String?)
    func logAddressRemoved(userWalletId: UserWalletId?, contactId: String?)
    func logContactDeleted(userWalletId: UserWalletId?, contactId: String?)
    func logSendFlowWidgetShown(userWalletId: UserWalletId?)
    func logContactSelected(userWalletId: UserWalletId?, contactId: String)
    func logAddressSubstitutedInSend(userWalletId: UserWalletId?, contactId: String)
    func logSelectAllNetworksTapped(userWalletId: UserWalletId?, action: AddressBookSelectAllAction)
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

    var parameterValue: Analytics.ParameterValue {
        switch self {
        case .settings: .settings
        case .sendFlow: .addressBookSourceSendFlow
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
    /// A user-cancelled card scan is not a failure the user sees, and duplicate name/address saves surface as
    /// inline errors logged where they're shown — everything else maps to the generic save-error event.
    func logSaveFailure(userWalletId: UserWalletId?, contactId: String?, error: Error) {
        guard !error.isCancellationError else {
            return
        }

        if let validationError = error as? AddressBookValidationError {
            switch validationError {
            case .addressAlreadySaved, .nameNotUnique:
                return
            default:
                break
            }
        }

        logSaveErrorShown(userWalletId: userWalletId, contactId: contactId, error: error)
    }
}
