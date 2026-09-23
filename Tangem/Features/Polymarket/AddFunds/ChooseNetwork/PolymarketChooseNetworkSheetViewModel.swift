//
//  PolymarketChooseNetworkSheetViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemPolymarketUI
import TangemUI

@MainActor
final class PolymarketChooseNetworkSheetViewModel: ObservableObject, FloatingSheetContentViewModel {
    @Published private(set) var rows: [PolymarketNetworkRowViewData]

    private weak var coordinator: PolymarketChooseNetworkSheetRoutable?

    init(networks: [PolymarketDepositNetwork], coordinator: PolymarketChooseNetworkSheetRoutable) {
        self.coordinator = coordinator

        rows = networks.map { network in
            PolymarketNetworkRowViewData(
                id: network.networkId,
                title: network.title,
                subtitle: network.subtitle,
                icon: network.icon,
                action: { [weak coordinator] in
                    coordinator?.chooseNetworkSheetRequestReceive(input: network.receiveInput)
                }
            )
        }
    }

    func close() {
        coordinator?.closeChooseNetworkSheet()
    }
}
