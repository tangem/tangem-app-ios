//
//  MultiWalletMainContentView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct MultiWalletMainContentView: View {
    @ObservedObject var viewModel: MultiWalletMainContentViewModel

    var body: some View {
        VStack {
            FixedSizeButtonWithLeadingIcon(
                title: Localization.organizeTokensTitle,
                icon: Assets.OrganizeTokens.filterIcon.image,
                action: viewModel.openOrganizeTokens
            )
            .infinityFrame(axis: .horizontal)
        }
    }
}

struct MultiWalletContentView_Preview: PreviewProvider {
    static let viewModel = MultiWalletMainContentViewModel(
        coordinator: MainCoordinator(),
        userWalletModel: UserWalletModelMock()
    )

    static var previews: some View {
        MultiWalletMainContentView(viewModel: viewModel)
    }
}
