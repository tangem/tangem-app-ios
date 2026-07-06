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
    func logContactListScreenOpened(walletId: String, source: AddressBookAnalyticsSource, contactsCount: Int) {
        Analytics.log(event: .addressBookContactListScreenOpened, params: [
            .addressBookWalletId: walletId,
            .source: source.parameterValue.rawValue,
            .contactsCount: "\(contactsCount)",
        ])
    }

    func logAddContactTapped(walletId: String, source: AddressBookAnalyticsSource) {
        Analytics.log(event: .addressBookAddContactTapped, params: [
            .addressBookWalletId: walletId,
            .source: source.parameterValue.rawValue,
        ])
    }

    func logContactScreenOpened(walletId: String, contactId: String?) {
        Analytics.log(event: .addressBookContactScreenOpened, params: [
            .addressBookWalletId: walletId,
            .contactId: contactId ?? "",
        ])
    }

    func logButtonSaveTo(walletId: String) {
        Analytics.log(event: .addressBookButtonSaveTo, params: [
            .addressBookWalletId: walletId,
        ])
    }

    func logContactSaved(walletId: String, contactId: String, mode: AddressBookAnalyticsMode) {
        Analytics.log(event: .addressBookContactSaved, params: [
            .addressBookWalletId: walletId,
            .contactId: contactId,
            .mode: mode.parameterValue.rawValue,
        ])
    }

    func logSaveErrorShown(walletId: String, contactId: String?, error: Error) {
        Analytics.log(event: .addressBookSaveErrorShown, params: [
            .addressBookWalletId: walletId,
            .contactId: contactId ?? "",
            .errorType: errorType(for: error).parameterValue.rawValue,
        ])
    }

    func logAddressScreenOpened(walletId: String) {
        Analytics.log(event: .addressBookAddressScreenOpened, params: [
            .addressBookWalletId: walletId,
        ])
    }

    func logAddressInvalid(walletId: String, contactId: String?) {
        Analytics.log(event: .addressBookAddressInvalid, params: [
            .addressBookWalletId: walletId,
            .contactId: contactId ?? "",
        ])
    }

    func logDuplicateNameErrorShown(walletId: String, contactId: String?) {
        Analytics.log(event: .addressBookDuplicateNameErrorShown, params: [
            .addressBookWalletId: walletId,
            .contactId: contactId ?? "",
        ])
    }

    func logAddressRemoved(walletId: String, contactId: String?) {
        Analytics.log(event: .addressBookAddressRemoved, params: [
            .addressBookWalletId: walletId,
            .contactId: contactId ?? "",
        ])
    }

    func logContactDeleted(walletId: String, contactId: String?) {
        Analytics.log(event: .addressBookContactDeleted, params: [
            .addressBookWalletId: walletId,
            .contactId: contactId ?? "",
        ])
    }

    func logSendFlowWidgetShown(walletId: String) {
        Analytics.log(event: .addressBookSendFlowWidgetShown, params: [
            .addressBookWalletId: walletId,
        ])
    }

    func logContactSelected(walletId: String, contactId: String) {
        Analytics.log(event: .addressBookContactSelected, params: [
            .addressBookWalletId: walletId,
            .contactId: contactId,
        ])
    }

    func logAddressSubstitutedInSend(walletId: String, contactId: String) {
        Analytics.log(event: .addressBookAddressSubstitutedInSend, params: [
            .addressBookWalletId: walletId,
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
