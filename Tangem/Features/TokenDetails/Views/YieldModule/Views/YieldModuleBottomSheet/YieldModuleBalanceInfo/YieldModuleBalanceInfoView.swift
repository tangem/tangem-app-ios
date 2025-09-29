//
//  YieldModuleBalanceInfoView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemUI
import TangemAssets

struct YieldModuleBalanceInfoView: View {
    private let viewModel: YieldModuleBalanceInfoViewModel

    init(viewModel: YieldModuleBalanceInfoViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        YieldModuleBottomSheetContainerView(
            title: Localization.yieldModuleBalanceInfoSheetTitle(viewModel.params.tokenItem.name),
            subtitle: Localization.yieldModuleBalanceInfoSheetSubtitle,
            button: .init(settings: .init(title: Localization.commonGotIt, style: .secondary, action: viewModel.onCloseTap)),
            header: { BottomSheetHeaderView(title: "", trailing: { CircleButton.close { viewModel.onCloseTap() } }) },
            topContent: { LendingPairIcon(tokenIconInfo: viewModel.getTokenIconInfo(), iconsSize: IconViewSizeSettings.tokenDetails.iconSize) },
            content: { Color.clear.frame(height: 6) }
        )
        .floatingSheetConfiguration { configuration in
            configuration.sheetBackgroundColor = Colors.Background.tertiary
        }
    }
}
