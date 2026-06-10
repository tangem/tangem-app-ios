//
//  AddressBookContactsListViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class AddressBookContactsListViewModel: ObservableObject {
    // MARK: - ViewState

    // MARK: - Dependencies

    private weak var coordinator: AddressBookContactsListRoutable?

    init(
        coordinator: AddressBookContactsListRoutable
    ) {
        self.coordinator = coordinator
    }
}
