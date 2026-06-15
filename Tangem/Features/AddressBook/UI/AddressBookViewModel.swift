//
//  AddressBookViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

final class AddressBookViewModel: ObservableObject {
    private weak var coordinator: AddressBookRoutable?

    init(coordinator: AddressBookRoutable) {
        self.coordinator = coordinator
    }
}
