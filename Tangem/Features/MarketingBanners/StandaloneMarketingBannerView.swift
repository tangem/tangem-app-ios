//
//  StandaloneMarketingBannerView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemLocalization

struct StandaloneMarketingBannerView: View {
    let viewModel: StandaloneMarketingBannerViewModel

    var body: some View {
        TangemMessageBanner(title: viewModel.title)
            .showGlowRing(false)
            .slotStart { leadingIcon }
            .slotEnd { trailingContent }
            .primaryButton(viewModel.action.map { action in
                .init(title: Localization.commonLearnMore, action: action)
            })
    }

    @ViewBuilder
    private var leadingIcon: some View {
        if viewModel.isDismissible {
            iconView
        }
    }

    @ViewBuilder
    private var trailingContent: some View {
        if viewModel.isDismissible {
            if let dismiss = viewModel.dismiss {
                TangemMessageBannerCloseButton(accessibilityLabel: Localization.commonClose, action: dismiss)
            }
        } else {
            iconView
        }
    }

    @ViewBuilder
    private var iconView: some View {
        if let iconURL = viewModel.iconURL {
            IconView(url: iconURL, size: CGSize(bothDimensions: 24)) {
                Color.clear
            }
        }
    }
}
