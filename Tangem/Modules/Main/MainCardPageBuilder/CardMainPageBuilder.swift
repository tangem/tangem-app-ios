//
//  CardMainPageBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

enum CardMainPageBuilder: Identifiable {
    case singleWallet(id: String, headerModel: CardHeaderViewModel, bodyModel: SingleWalletContentCoordinator)
    case multiWallet(id: String, headerModel: CardHeaderViewModel, bodyModel: MultiWalletContentCoordinator)

    var id: String {
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
            CardHeaderView(viewModel: headerModel)
        case .multiWallet(_, let headerModel, _):
            CardHeaderView(viewModel: headerModel)
        }
    }

    @ViewBuilder
    var body: some View {
        switch self {
        case .singleWallet(_, _, let bodyModel):
            SingleWalletContentCoordinatorView(coordinator: bodyModel)
        case .multiWallet(_, _, let bodyModel):
            MultiWalletContentCoordinatorView(coordinator: bodyModel)
        }
    }
}
