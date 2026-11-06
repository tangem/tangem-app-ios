//
//  TangemPayMoneyAccountCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

struct TangemPayMoneyAccountCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: TangemPayMoneyAccountCoordinator

    var body: some View {
        rootView
            .navigationLinks(links)
            .addressBookContactManagementSheet($coordinator.contactManagementCoordinator)
            .modal(
                item: $coordinator.addFundsViewModel,
                contentLayout: .intrinsic,
                dragIndicator: .hidden,
                navigation: .title(Localization.tangempayCardDetailsAddFunds),
                onDismiss: coordinator.addFundsDidDismiss,
                content: { TangemPayMoneyAccountAddFundsView(viewModel: $0) }
            )
            .sheet(item: $coordinator.sendCoordinator) {
                SendCoordinatorView(coordinator: $0)
                    .softTopScrollEdgeEffect()
            }
    }
}

// MARK: - Root View

private extension TangemPayMoneyAccountCoordinatorView {
    var rootView: some View {
        TangemPayMoneyAccountFactory.makeView(
            moneyAccount: coordinator.options.moneyAccount,
            userWalletModel: coordinator.options.userWalletModel,
            output: { [weak coordinator] in
                coordinator?.handle($0)
            }
        )
    }
}

// MARK: - Destinations

private extension TangemPayMoneyAccountCoordinatorView {
    var links: some View {
        NavHolder()
            .navigation(item: $coordinator.tokenDetailsCoordinator) {
                TokenDetailsCoordinatorView(coordinator: $0)
            }
    }
}
