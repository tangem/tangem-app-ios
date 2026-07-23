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
import TangemFoundation

struct CommonAddressBookAnalyticsLogger: AddressBookAnalyticsLogger {
    func logContactListScreenOpened(userWalletId: UserWalletId?, source: AddressBookAnalyticsSource, contactsCount: Int) {
        Analytics.log(event: .addressBookContactListScreenOpened, params: withWalletId(userWalletId, [
            .source: source.parameterValue.rawValue,
            .contactsCount: "\(contactsCount)",
        ]))
    }

    func logAddContactTapped(userWalletId: UserWalletId?, source: AddressBookAnalyticsSource) {
        Analytics.log(event: .addressBookAddContactTapped, params: withWalletId(userWalletId, [
            .source: source.parameterValue.rawValue,
        ]))
    }

    func logContactScreenOpened(userWalletId: UserWalletId?, contactId: String?) {
        Analytics.log(event: .addressBookContactScreenOpened, params: withWalletId(userWalletId, [
            .contactId: contactId ?? "",
        ]))
    }

    func logButtonSaveTo() {
        Analytics.log(.addressBookButtonSaveTo)
    }

    func logContactSaved(userWalletId: UserWalletId?, contactId: String, mode: AddressBookAnalyticsMode) {
        Analytics.log(event: .addressBookContactSaved, params: withWalletId(userWalletId, [
            .contactId: contactId,
            .mode: mode.parameterValue.rawValue,
        ]))
    }

    func logSaveErrorShown(userWalletId: UserWalletId?, contactId: String?, error: Error) {
        Analytics.log(event: .addressBookSaveErrorShown, params: withWalletId(userWalletId, [
            .contactId: contactId ?? "",
            .errorType: errorType(for: error).parameterValue.rawValue,
        ]))
    }

    func logAddressScreenOpened() {
        Analytics.log(.addressBookAddressScreenOpened)
    }

    func logSelectAllNetworksTapped(userWalletId: UserWalletId?, action: AddressBookSelectAllAction) {
        Analytics.log(event: .addressBookSelectAllNetworksTapped, params: withWalletId(userWalletId, [
            .action: action.parameterValue.rawValue,
        ]))
    }

    func logAddressInvalid(userWalletId: UserWalletId?, contactId: String?) {
        Analytics.log(event: .addressBookAddressInvalid, params: withWalletId(userWalletId, [
            .contactId: contactId ?? "",
        ]))
    }

    func logDuplicateNameErrorShown(userWalletId: UserWalletId?, contactId: String?) {
        Analytics.log(event: .addressBookDuplicateNameErrorShown, params: withWalletId(userWalletId, [
            .contactId: contactId ?? "",
        ]))
    }

    func logAddressRemoved(userWalletId: UserWalletId?, contactId: String?) {
        Analytics.log(event: .addressBookAddressRemoved, params: withWalletId(userWalletId, [
            .contactId: contactId ?? "",
        ]))
    }

    func logContactDeleted(userWalletId: UserWalletId?, contactId: String?) {
        Analytics.log(event: .addressBookContactDeleted, params: withWalletId(userWalletId, [
            .contactId: contactId ?? "",
        ]))
    }

    func logSendFlowWidgetShown(userWalletId: UserWalletId?) {
        Analytics.log(event: .addressBookSendFlowWidgetShown, params: withWalletId(userWalletId, [:]))
    }

    func logContactSelected(userWalletId: UserWalletId?, contactId: String) {
        Analytics.log(event: .addressBookContactSelected, params: withWalletId(userWalletId, [
            .contactId: contactId,
        ]))
    }

    func logAddressSubstitutedInSend(userWalletId: UserWalletId?, contactId: String) {
        Analytics.log(event: .addressBookAddressSubstitutedInSend, params: withWalletId(userWalletId, [
            .contactId: contactId,
        ]))
    }
}

// MARK: - Error type mapping

private extension CommonAddressBookAnalyticsLogger {
    func withWalletId(_ userWalletId: UserWalletId?, _ params: [Analytics.ParameterKey: String]) -> [Analytics.ParameterKey: String] {
        guard let userWalletId else { return params }
        var params = params
        params[.addressBookWalletId] = userWalletId.hashedStringValue
        return params
    }

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
