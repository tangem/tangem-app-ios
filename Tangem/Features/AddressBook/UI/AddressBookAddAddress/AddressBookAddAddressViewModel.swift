//
//  AddressBookAddAddressViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

final class AddressBookAddAddressViewModel: ObservableObject, Identifiable {
    private weak var coordinator: AddressBookAddAddressRoutable?

    init(coordinator: AddressBookAddAddressRoutable) {
        self.coordinator = coordinator
    }

    func userDidRequestDismiss() {
        coordinator?.dismissAddAddress()
    }
}
