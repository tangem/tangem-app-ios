//
//  AddressBookAddAddressInteractorTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import Testing
import BlockchainSdk
import TangemFoundation
@testable import Tangem

@Suite("CommonAddressBookAddAddressInteractor — save availability")
struct AddressBookAddAddressInteractorTests {
    private let xrp = Blockchain.xrp(curve: .secp256k1)
    private let xrpAddress = "rGm7WCVp9gb4jZHWTEtGUr4dd74z2XuWhE"

    @Test("Save is disabled while the destination tag is invalid and re-enabled once it is fixed")
    func invalidDestinationTagDisablesSave() throws {
        let output = OutputMock()
        let interactor = makeInteractor(output: output)
        var isEnabled = false
        let subscription = interactor.isAddAddressEnabledPublisher.sink { isEnabled = $0 }
        defer { subscription.cancel() }

        interactor.update(address: xrpAddress, source: .textField)
        interactor.update(selectedNetworks: [xrp])
        #expect(isEnabled, "a valid address with a selected network and no memo is saveable")

        // XRP destination tags are UInt32; letters are rejected by `TransactionParamsBuilder`.
        interactor.update(additionalField: "not-a-tag")
        #expect(!isEnabled, "an invalid destination tag must block saving instead of dropping the tag")

        interactor.update(additionalField: "12345")
        #expect(isEnabled)

        interactor.userDidRequestSave()
        let entry = try #require(output.savedEntries.first)
        #expect(entry.memo == "12345")
        #expect(entry.blockchain == xrp)
    }

    @Test("Clearing an invalid destination tag re-enables saving without a memo")
    func clearingInvalidTagReenablesSave() {
        let output = OutputMock()
        let interactor = makeInteractor(output: output)
        var isEnabled = false
        let subscription = interactor.isAddAddressEnabledPublisher.sink { isEnabled = $0 }
        defer { subscription.cancel() }

        interactor.update(address: xrpAddress, source: .textField)
        interactor.update(selectedNetworks: [xrp])
        interactor.update(additionalField: "abc")
        #expect(!isEnabled)

        interactor.update(additionalField: "")
        #expect(isEnabled)

        interactor.userDidRequestSave()
        #expect(output.savedEntries.first?.memo == nil)
    }

    private func makeInteractor(output: OutputMock) -> CommonAddressBookAddAddressInteractor {
        var config = UserWalletConfigStub()
        config.supportedBlockchains = [xrp]

        let userWalletInfo = UserWalletInfo(
            name: "Test",
            id: UserWalletId(value: Data([0x01])),
            config: config,
            backupState: .valid,
            refcode: nil,
            signerFactory: TangemSignerFactory(),
            emailDataProvider: EmailDataProviderStub()
        )

        return CommonAddressBookAddAddressInteractor(
            userWalletInfo: userWalletInfo,
            contactId: nil,
            output: output,
            options: .add,
            reservedContacts: [],
            analyticsLogger: AnalyticsLoggerMock()
        )
    }
}

// MARK: - Test doubles

private final class OutputMock: AddressBookAddAddressOutput {
    private(set) var savedEntries: [AddressBookEntryDraft] = []

    var contactHasUnsavedChanges: Bool { false }
    var contactEntries: [AddressBookEntryDraft] { [] }
    var contactDisplayName: String { "Contact" }

    func userDidAddAddress(entries: [AddressBookEntryDraft], replacing: [AddressBookAddressEntryID]) {
        savedEntries = entries
    }
}

private struct AnalyticsLoggerMock: AddressBookAnalyticsLogger {
    func logContactListScreenOpened(userWalletId: UserWalletId?, source: AddressBookAnalyticsSource, contactsCount: Int) {}
    func logAddContactTapped(userWalletId: UserWalletId?, source: AddressBookAnalyticsSource) {}
    func logContactScreenOpened(userWalletId: UserWalletId?, contactId: String?) {}
    func logButtonSaveTo() {}
    func logContactSaved(userWalletId: UserWalletId?, contactId: String, mode: AddressBookAnalyticsMode) {}
    func logSaveErrorShown(userWalletId: UserWalletId?, contactId: String?, error: Error) {}
    func logAddressScreenOpened() {}
    func logAddressInvalid(userWalletId: UserWalletId?, contactId: String?) {}
    func logDuplicateNameErrorShown(userWalletId: UserWalletId?, contactId: String?) {}
    func logAddressRemoved(userWalletId: UserWalletId?, contactId: String?) {}
    func logContactDeleted(userWalletId: UserWalletId?, contactId: String?) {}
    func logSendFlowWidgetShown(userWalletId: UserWalletId?) {}
    func logContactSelected(userWalletId: UserWalletId?, contactId: String) {}
    func logAddressSubstitutedInSend(userWalletId: UserWalletId?, contactId: String) {}
    func logSelectAllNetworksTapped(userWalletId: UserWalletId?, action: AddressBookSelectAllAction) {}
}
