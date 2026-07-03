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
    func chooseAddressDidSelect(_ group: AddressBookContactAddressGroup)
}

final class ChooseAddressViewModel: FloatingSheetContentViewModel {
    let rows: [ChooseAddressRowViewModel]

    private weak var router: ChooseAddressRoutable?
    private weak var output: ChooseAddressOutput?

    init(
        groups: [AddressBookContactAddressGroup],
        router: ChooseAddressRoutable?,
        output: ChooseAddressOutput?
    ) {
        self.router = router
        self.output = output

        rows = groups.map { group in
            let subtitle: String
            if let network = group.networks.singleElement {
                subtitle = network.blockchain.displayName
            } else {
                subtitle = Localization.commonNetworksCount(group.networks.count)
            }

            return ChooseAddressRowViewModel(group: group, subtitle: subtitle) { [weak router, weak output] in
                router?.dismissChooseAddress()
                output?.chooseAddressDidSelect(group)
            }
        }
    }

    func close() {
        router?.dismissChooseAddress()
    }
}
