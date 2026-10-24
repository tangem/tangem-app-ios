//
//  YieldModuleAboutApyView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemUI
import TangemAssets

struct YieldModuleAboutApyView: View {
    private let viewModel: YieldModuleAboutApyViewModel

    init(viewModel: YieldModuleAboutApyViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        YieldModuleBottomSheetContainerView(
            title: Localization.yieldModuleAboutApySheetTitle,
            subtitle: Localization.yieldModuleAboutApySheetSubtitle,
            button: MainButton(settings: .init(title: Localization.commonGotIt, style: .secondary, action: viewModel.onCloseTap)),
            header: { BottomSheetHeaderView(title: "", trailing: { NavigationBarButton.close(action: viewModel.onCloseTap) }) },
            content: { apyBreakdownSection }
        )
        .floatingSheetConfiguration { configuration in
            configuration.sheetBackgroundColor = Colors.Background.tertiary
        }
    }

    private var apyBreakdownSection: some View {
        VStack(spacing: 12) {
            YieldFeeSection(
                sectionState: .init(feeState: .loaded(text: viewModel.baseApyText)),
                leadingTitle: Localization.yieldModuleAboutApyBaseYieldTitle,
                needsBackground: false
            )

            Separator(color: Colors.Stroke.primary)
                .padding(.horizontal, 4)

            YieldFeeSection(
                sectionState: .init(feeState: .loaded(text: viewModel.rewardsApyText)),
                leadingTitle: Localization.yieldModuleAboutApyExtraRewardsTitle,
                needsBackground: false
            )
        }
        .defaultRoundedBackground(with: Colors.Background.action)
    }
}
