//
//  AddressBookWalletPickerViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemUI

protocol AddressBookWalletPickerOutput: AnyObject {
    func walletPickerDidSelect(_ addressBookWallet: AddressBookWallet)
}

protocol AddressBookWalletPickerRoutable: AnyObject {
    func dismissWalletPicker()
}

final class AddressBookWalletPickerViewModel: FloatingSheetContentViewModel {
    let itemViewModels: [WalletSelectorItemViewModel]

    private let dataSource: AddressBookWalletSelectorDataSource
    private weak var routable: AddressBookWalletPickerRoutable?

    init(
        addressBookWallets: [AddressBookWallet],
        output: AddressBookWalletPickerOutput,
        routable: AddressBookWalletPickerRoutable
    ) {
        self.routable = routable

        let dataSource = AddressBookWalletSelectorDataSource(
            addressBookWallets: addressBookWallets,
            onSelect: { [weak output, weak routable] addressBookWallet in
                output?.walletPickerDidSelect(addressBookWallet)
                routable?.dismissWalletPicker()
            }
        )
        self.dataSource = dataSource
        itemViewModels = dataSource.itemViewModels
    }

    func close() {
        routable?.dismissWalletPicker()
    }
}
