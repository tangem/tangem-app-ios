//
//  AddressBookContactManagementInteractor.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemAccounts
import TangemFoundation
import TangemUI

protocol AddressBookContactManagementInteractor {
    var title: String { get }
    var contactId: AddressBookContactID? { get }
    var mainButtonTitle: String { get }
    var saveErrorMessage: String? { get }

    var contactNamePublisher: AnyPublisher<String, Never> { get }
    var contactColorPublisher: AnyPublisher<AccountModel.CompositeIcon.Color, Never> { get }

    var addressesPublisher: AnyPublisher<AddressBookContactDraftEntries?, Never> { get }
    var walletPublisher: AnyPublisher<AddressBookWallet, Never> { get }

    var possibleToAddNewAddress: AnyPublisher<Bool, Never> { get }
    var possibleToDeleteContact: AnyPublisher<Bool, Never> { get }

    var isMainButtonEnabledPublisher: AnyPublisher<Bool, Never> { get }
    var isNameTakenPublisher: AnyPublisher<Bool, Never> { get }
    var reservedContacts: [AddressBookContact] { get }
    var mainButtonIconPublisher: AnyPublisher<MainButton.Icon?, Never> { get }

    var hasUnsavedChanges: Bool { get }

    func update(name: String)
    func update(color: AccountModel.CompositeIcon.Color)
    func update(addressBookWallet: AddressBookWallet)

    func update(entries: [AddressBookEntryDraft], replacing ids: [AddressBookAddressEntryID]) throws
    func deleteAddress(id: AddressBookAddressEntryID)

    func logContactScreenOpened()
    func logWalletPickerOpened()
    func logAddressRemoved()

    @discardableResult
    func save() async throws -> AddressBookContactID
    func delete() async throws
}
