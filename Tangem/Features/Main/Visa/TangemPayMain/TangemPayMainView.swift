//
//  TangemPayMainView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

struct TangemPayMainView: View {
    let viewModel: TangemPayMainViewModel

    var body: some View {
        CardsInfoPagerView(
            data: [viewModel],
            selectedIndex: .constant(0),
            headerFactory: {
                MainHeaderView(viewModel: $0.mainHeaderViewModel)
            },
            contentFactory: {
                VisaWalletMainContentView(viewModel: $0.viewWalletMainContentViewModel)
            }
        )
        .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
    }
}
