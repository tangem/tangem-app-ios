//
//  ChooseAddressViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemFoundation
import TangemLocalization
import TangemUI

protocol ChooseAddressRoutable: AnyObject {
    func dismissChooseAddress()
}

protocol ChooseAddressOutput: AnyObject {
    func chooseAddressDidSelect(_ group: AddressBookContactAddressGroup, of contact: AddressBookContact)
}

final class ChooseAddressViewModel: FloatingSheetContentViewModel {
    let rows: [ChooseAddressRowViewModel]

    private weak var router: ChooseAddressRoutable?

    init(
        groups: [AddressBookContactAddressGroup],
        router: ChooseAddressRoutable?,
        onSelect: @escaping (AddressBookContactAddressGroup) -> Void
    ) {
        self.router = router

        rows = groups.map { group in
            let subtitle: String
            if let network = group.networks.singleElement {
                subtitle = network.blockchain.displayName
            } else {
                subtitle = Localization.commonNetworksCount(group.networks.count)
            }

            return ChooseAddressRowViewModel(group: group, subtitle: subtitle) { [weak router] in
                router?.dismissChooseAddress()
                onSelect(group)
            }
        }
    }

    func close() {
        router?.dismissChooseAddress()
    }
}
