//
//  ReferralCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemLocalization

struct ReferralCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: ReferralCoordinator

    var body: some View {
        ZStack {
            if let model = coordinator.referralViewModel {
                ReferralView(viewModel: model)
                    .navigationLinks(links)
            }
        }
    }

    @ViewBuilder
    private var links: some View {
        NavHolder()
            .navigation(item: $coordinator.tosViewModel) {
                WebViewContainer(viewModel: $0)
            }
            .floatingSheetContent(for: AccountSelectorViewModel.self) { viewModel in
                VStack(spacing: 0) {
                    BottomSheetHeaderView(
                        title: Localization.commonChooseAccount,
                        trailing: {
                            CircleButton.close(action: coordinator.closeSheet)
                        }
                    )
                    .padding(.horizontal, 16)

                    AccountSelectorView(viewModel: viewModel)
                }
                .floatingSheetConfiguration { config in
                    config.backgroundInteractionBehavior = .tapToDismiss
                }
            }
    }
}
