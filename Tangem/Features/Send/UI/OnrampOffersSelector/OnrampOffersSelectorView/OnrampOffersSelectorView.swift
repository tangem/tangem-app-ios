//
//  OnrampOffersSelectorView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

struct OnrampOffersSelectorView: View {
    @ObservedObject var viewModel: OnrampOffersSelectorViewModel

    var backButtonVisible: Bool {
        switch viewModel.viewState {
        case .paymentMethods: false
        case .providers: true
        }
    }

    var subtitle: String {
        switch viewModel.viewState {
        case .paymentMethods: Localization.onrampPaymentMethodSubtitle
        case .providers: Localization.onrampProvidersSubtitle
        }
    }

    var body: some View {
        VStack(spacing: .zero) {
            BottomSheetHeaderView(
                title: Localization.onrampAllOffersButtonTitle,
                subtitle: subtitle,
                leading: {
                    CircleButton.back(action: viewModel.back).visible(backButtonVisible)
                },
                trailing: {
                    CircleButton.close(action: viewModel.close)
                }
            )
            .subtitleSpacing(0)
            .padding(.horizontal, 16)

            GroupedScrollView(alignment: .leading, spacing: 8) {
                content
            }
            .scrollBounceBehaviorBackport(.basedOnSize)
            .animation(.contentFrameUpdate, value: viewModel.viewState)
            .padding(.bottom, 16)
        }
        .floatingSheetConfiguration { configuration in
            configuration.sheetBackgroundColor = Colors.Background.tertiary
            configuration.sheetFrameUpdateAnimation = .contentFrameUpdate
            configuration.backgroundInteractionBehavior = .tapToDismiss
        }
    }

    @ViewBuilder
    var content: some View {
        switch viewModel.viewState {
        case .paymentMethods:
            ForEach(viewModel.paymentMethods) {
                OnrampProviderItemView(viewModel: $0)
            }
        case .providers(let providers):
            ForEach(providers) {
                OnrampOfferView(viewModel: $0)
            }
        }
    }
}

private extension Animation {
    static let contentFrameUpdate = Animation.curve(.easeInOutRefined, duration: 0.5)
}
