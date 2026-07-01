//
//  ChooseAddressRowViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct ChooseAddressRowViewModel: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let addressIcon: AddressBlockiesIconViewData
    let onTap: () -> Void

    init(group: AddressBookContactAddressGroup, subtitle: String, onTap: @escaping () -> Void) {
        id = group.id
        title = AddressFormatter(address: group.address).truncated(prefixLimit: 12, suffixLimit: 12)
        self.subtitle = subtitle
        addressIcon = AddressIconProvider.makeBlockiesIconViewData(address: group.address)
        self.onTap = onTap
    }
}
