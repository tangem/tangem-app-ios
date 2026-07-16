//
//  CommonAddressBookAnalyticsLogger.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import TangemNetworkUtils

struct CommonAddressBookAnalyticsLogger: AddressBookAnalyticsLogger {
    func logContactListScreenOpened(source: AddressBookAnalyticsSource, contactsCount: Int) {
        Analytics.log(event: .addressBookContactListScreenOpened, params: [
            .source: source.parameterValue.rawValue,
            .contactsCount: "\(contactsCount)",
        ])
    }

    func logAddContactTapped(source: AddressBookAnalyticsSource) {
        Analytics.log(event: .addressBookAddContactTapped, params: [
            .source: source.parameterValue.rawValue,
        ])
    }

    func logContactScreenOpened(contactId: String?) {
        Analytics.log(event: .addressBookContactScreenOpened, params: [
            .contactId: contactId ?? "",
        ])
    }

    func logButtonSaveTo() {
        Analytics.log(.addressBookButtonSaveTo)
    }

    func logContactSaved(contactId: String, mode: AddressBookAnalyticsMode) {
        Analytics.log(event: .addressBookContactSaved, params: [
            .contactId: contactId,
            .mode: mode.parameterValue.rawValue,
        ])
    }

    func logSaveErrorShown(contactId: String?, error: Error) {
        Analytics.log(event: .addressBookSaveErrorShown, params: [
            .contactId: contactId ?? "",
            .errorType: errorType(for: error).parameterValue.rawValue,
        ])
    }

    func logAddressScreenOpened() {
        Analytics.log(.addressBookAddressScreenOpened)
    }

    func logSelectAllNetworksTapped(action: AddressBookSelectAllAction) {
        Analytics.log(event: .addressBookSelectAllNetworksTapped, params: [
            .action: action.parameterValue.rawValue,
        ])
    }

    func logAddressInvalid(contactId: String?) {
        Analytics.log(event: .addressBookAddressInvalid, params: [
            .contactId: contactId ?? "",
        ])
    }

    func logDuplicateNameErrorShown(contactId: String?) {
        Analytics.log(event: .addressBookDuplicateNameErrorShown, params: [
            .contactId: contactId ?? "",
        ])
    }

    func logAddressRemoved(contactId: String?) {
        Analytics.log(event: .addressBookAddressRemoved, params: [
            .contactId: contactId ?? "",
        ])
    }

    func logContactDeleted(contactId: String?) {
        Analytics.log(event: .addressBookContactDeleted, params: [
            .contactId: contactId ?? "",
        ])
    }

    func logSendFlowWidgetShown() {
        Analytics.log(.addressBookSendFlowWidgetShown)
    }

    func logContactSelected(contactId: String) {
        Analytics.log(event: .addressBookContactSelected, params: [
            .contactId: contactId,
        ])
    }

    func logAddressSubstitutedInSend(contactId: String) {
        Analytics.log(event: .addressBookAddressSubstitutedInSend, params: [
            .contactId: contactId,
        ])
    }
}

// MARK: - Error type mapping

private extension CommonAddressBookAnalyticsLogger {
    enum SaveErrorType {
        case network
        case server
        case signing

        var parameterValue: Analytics.ParameterValue {
            switch self {
            case .network: .marketsErrorTypeNetwork
            case .server: .addressBookErrorServer
            case .signing: .addressBookErrorSigning
            }
        }
    }

    func errorType(for error: Error) -> SaveErrorType {
        switch error {
        case AddressBookNetworkServiceError.underlyingError(let underlyingError):
            errorType(for: underlyingError)
        case is TangemSdkError:
            .signing
        case let error where isConnectivityError(error):
            .network
        default:
            .server
        }
    }

    func isConnectivityError(_ error: Error) -> Bool {
        if error.networkErrorCode != nil {
            return true
        }

        return error.asMoyaError?.underlyingError?.networkErrorCode != nil
    }
}
