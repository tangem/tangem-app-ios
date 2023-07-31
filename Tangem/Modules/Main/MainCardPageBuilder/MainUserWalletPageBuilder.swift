//
//  MainUserWalletPageBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

enum MainUserWalletPageBuilder: Identifiable {
    case singleWallet(id: UserWalletId, headerModel: MainHeaderViewModel, bodyModel: SingleWalletMainContentCoordinator)
    case multiWallet(id: UserWalletId, headerModel: MainHeaderViewModel, bodyModel: MultiWalletMainContentCoordinator)

    var id: UserWalletId {
        switch self {
        case .singleWallet(let id, _, _):
            return id
        case .multiWallet(let id, _, _):
            return id
        }
    }

    @ViewBuilder
    var header: some View {
        switch self {
        case .singleWallet(_, let headerModel, _):
            MainHeaderView(viewModel: headerModel)
        case .multiWallet(_, let headerModel, _):
            MainHeaderView(viewModel: headerModel)
        }
    }

    @ViewBuilder
    var body: some View {
        switch self {
        case .singleWallet(_, _, let bodyModel):
            SingleWalletMainContentCoordinatorView(coordinator: bodyModel)
        case .multiWallet(_, _, let bodyModel):
            MultiWalletMainContentCoordinatorView(coordinator: bodyModel)
        }
    }
}
