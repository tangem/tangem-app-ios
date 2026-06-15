//
//  AddressBookContactManagementInteractor.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemAccounts
import TangemUI

protocol AddressBookContactManagementInteractor {
    var title: String { get }

    var contactNamePublisher: AnyPublisher<String, Never> { get }
    var contactColorPublisher: AnyPublisher<AccountModel.CompositeIcon.Color, Never> { get }

    var addressesPublisher: AnyPublisher<[AddressBookContactManagementViewModel.DraftRow], Never> { get }
    var walletPublisher: AnyPublisher<AddressBookContactManagementViewModel.WalletRowType?, Never> { get }

    var possibleToAddNewAddress: AnyPublisher<Bool, Never> { get }
    var possibleToDeleteContact: AnyPublisher<Bool, Never> { get }

    var isMainButtonEnabledPublisher: AnyPublisher<Bool, Never> { get }
    var mainButtonIconPublisher: AnyPublisher<MainButton.Icon?, Never> { get }

    func update(name: String)
    func update(color: AccountModel.CompositeIcon.Color)

    func add(address: AddressBookContactManagementViewModel.DraftRow) throws
    func deleteAddress(id: String)

    func save() async throws
    func delete() async throws
}

enum AddressBookManagementError: Error {
    case walletUnavailable
}
