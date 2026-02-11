//
//  TangemPayAddFundsSheetView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

struct TangemPayAddFundsSheetView: View {
    @ObservedObject var viewModel: TangemPayAddFundsSheetViewModel

    var body: some View {
        VStack(spacing: .zero) {
            BottomSheetHeaderView(title: Localization.tangempayCardDetailsAddFunds, trailing: {
                NavigationBarButton.close(action: viewModel.close)
            })

            GroupedSection(viewModel.options) { option in
                TangemPayAddFundsSheetOptionView(option: option, action: {
                    viewModel.userDidTapOption(option: option)
                })
            } header: {
                DefaultHeaderView(Localization.tangempayCardDetailsAddFundsSubtitle)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
            }
            .backgroundColor(Colors.Background.action)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
        .floatingSheetConfiguration { configuration in
            configuration.sheetBackgroundColor = Colors.Background.tertiary
            configuration.backgroundInteractionBehavior = .tapToDismiss
        }
    }
}
