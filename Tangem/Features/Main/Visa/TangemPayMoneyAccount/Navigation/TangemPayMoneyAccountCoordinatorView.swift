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
    }
}

// MARK: - Root View

private extension TangemPayMoneyAccountCoordinatorView {
    var rootView: some View {
        TangemPayMoneyAccountFactory.makeView(
            userWalletModel: coordinator.options.userWalletModel,
            output: { [weak coordinator] in
                coordinator?.handle($0)
            }
        )
    }
}

// MARK: - Destinations

private extension TangemPayMoneyAccountCoordinatorView {}
