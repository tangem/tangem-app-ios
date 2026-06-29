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

final class ChooseAddressViewModel: FloatingSheetContentViewModel {
    let rows: [ChooseAddressRowViewModel]

    private let onClose: () -> Void

    init(
        groups: [AddressBookContactAddressGroup],
        onSelect: @escaping (AddressBookContactAddressGroup) -> Void,
        onClose: @escaping () -> Void
    ) {
        self.onClose = onClose

        rows = groups.map { group in
            let subtitle: String
            if let network = group.networks.singleElement {
                subtitle = network.blockchain.displayName
            } else {
                subtitle = Localization.commonNetworksCount(group.networks.count)
            }

            return ChooseAddressRowViewModel(group: group, subtitle: subtitle, onTap: { onSelect(group) })
        }
    }

    func close() {
        onClose()
    }
}
