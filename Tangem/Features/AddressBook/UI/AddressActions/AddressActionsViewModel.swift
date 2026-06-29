//
//  AddressActionsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import TangemUI

protocol AddressActionsOutput: AnyObject {
    func addressActionsDidRequestCopy(_ group: AddressBookContactAddressGroup)
    func addressActionsDidRequestEdit(_ group: AddressBookContactAddressGroup)
    func addressActionsDidRequestRemove(_ group: AddressBookContactAddressGroup)
}

protocol AddressActionsRoutable: AnyObject {
    func dismissAddressActions()
}

final class AddressActionsViewModel: FloatingSheetContentViewModel {
    let addressIconViewModel: AddressIconViewModel
    let address: String
    let networksSubtitle: String

    private let group: AddressBookContactAddressGroup
    private weak var output: AddressActionsOutput?
    private weak var routable: AddressActionsRoutable?

    init(
        group: AddressBookContactAddressGroup,
        output: AddressActionsOutput,
        routable: AddressActionsRoutable
    ) {
        self.group = group
        self.output = output
        self.routable = routable

        addressIconViewModel = AddressIconViewModel(address: group.address)
        address = AddressFormatter(address: group.address).truncated(prefixLimit: 12, suffixLimit: 12)
        networksSubtitle = Localization.commonNetworksCount(group.networks.count)
    }

    func copy() {
        output?.addressActionsDidRequestCopy(group)
    }

    func edit() {
        routable?.dismissAddressActions()
        output?.addressActionsDidRequestEdit(group)
    }

    func remove() {
        output?.addressActionsDidRequestRemove(group)
        routable?.dismissAddressActions()
    }

    func close() {
        routable?.dismissAddressActions()
    }
}
