//
//  EarnDeeplinkContainerView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct EarnDeeplinkContainerView: View {
    @StateObject private var coordinator: EarnDeeplinkCoordinator

    init(earnType: EarnFilterType?, networkId: String?) {
        _coordinator = StateObject(
            wrappedValue: EarnDeeplinkCoordinator(
                earnType: earnType,
                networkId: networkId
            )
        )
    }

    var body: some View {
        EarnDetailCoordinatorView(coordinator: coordinator.earnCoordinator)
            .fullScreenCover(item: $coordinator.tokenDetailsCoordinator) { tokenDetailsCoordinator in
                NavigationStack {
                    TokenDetailsCoordinatorView(coordinator: tokenDetailsCoordinator)
                        .toolbar {
                            NavigationToolbarButton.close(
                                placement: .topBarLeading,
                                action: coordinator.dismissTokenDetails
                            )
                        }
                }
                .tint(Colors.Text.primary1)
            }
    }
}
