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

    init(earnType: EarnFilterType?, networkId: String?, dismissAction: @escaping () -> Void) {
        _coordinator = StateObject(
            wrappedValue: EarnDeeplinkCoordinator(
                earnType: earnType,
                networkId: networkId,
                dismissAction: dismissAction
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
            .fullScreenCover(item: $coordinator.yieldModulePromoCoordinator) { promoCoordinator in
                NavigationStack {
                    YieldModulePromoCoordinatorView(coordinator: promoCoordinator)
                        .toolbar {
                            NavigationToolbarButton.close(
                                placement: .topBarLeading,
                                action: { promoCoordinator.dismiss() }
                            )
                        }
                }
                .tint(Colors.Text.primary1)
            }
            .sheet(item: $coordinator.yieldModuleActiveCoordinator) { activeCoordinator in
                YieldModuleActiveCoordinatorView(coordinator: activeCoordinator)
                    .onDisappear {
                        activeCoordinator.dismiss()
                    }
            }
    }
}
