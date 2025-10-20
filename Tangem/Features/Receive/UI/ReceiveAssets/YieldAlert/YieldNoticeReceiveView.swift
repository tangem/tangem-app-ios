//
//  YieldNoticeReceiveView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemUI
import TangemAssets

struct YieldNoticeReceiveView: View {
    @ObservedObject var viewModel: TokenAlertReceiveAssetsViewModel

    var body: some View {
        YieldModuleBottomSheetContainerView(
            title: Localization.yieldModuleAlertTitle(viewModel.currencySymbol),
            subtitle: Localization.yieldModuleAlertDescription,
            button: MainButton(settings: .init(title: Localization.commonGotIt, style: .secondary, action: viewModel.onGotItTapAction)),
            topContent: {
                LendingPairIcon(tokenId: viewModel.tokenId, iconsSize: IconViewSizeSettings.tokenDetails.iconSize)
            }
        )
    }
}
