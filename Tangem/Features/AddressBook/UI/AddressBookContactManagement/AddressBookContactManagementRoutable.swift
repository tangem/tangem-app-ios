//
//  AddressBookContactManagementRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol AddressBookContactManagementRoutable: AnyObject, AddressActionsRoutable {
    func dismissContactManagement()
    func openAddAddress(userWalletInfo: UserWalletInfo, contactId: AddressBookContactID?, output: any AddressBookAddAddressOutput, options: AddressBookAddAddressOptions, reservedContacts: [AddressBookContact])
    func presentAddressActions(_ viewModel: AddressActionsViewModel)
    func presentWalletPicker(_ viewModel: AccountSelectorViewModel)
    func dismissWalletPicker()
}
