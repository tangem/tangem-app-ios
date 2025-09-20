//
//  YieldAlertReceiveAssetsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemUI
import TangemAssets

struct YieldAlertReceiveAssetsView: View {
    @ObservedObject var viewModel: TokenAlertReceiveAssetsViewModel

    var body: some View {
        // [REDACTED_TODO_COMMENT]
        YieldModuleBottomSheetContainerView(
            title: "Your USDT is deposited in Aave ",
            subtitle: "When you top up, your funds will be automatically sent to Aave to start earning interest. A small fee equal to $0.15 will be deducted to cover the transaction.",
            button: .init(settings: .init(title: Localization.commonGotIt, style: .secondary, action: viewModel.onGotItTapAction)),
            topContent: { lendingPairIcon }
        )
    }

    private var lendingPairIcon: some View {
        ZStack {
            TokenIcon(
                tokenIconInfo: viewModel.tokenIconInfo,
                size: IconViewSizeSettings.tokenDetails.iconSize
            )
            .offset(x: -16)

            Assets.YieldModule.yieldModuleAaveLogo.image
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)
                .background(
                    Circle()
                        .fill(Colors.Background.tertiary)
                        .frame(width: 50, height: 50)
                )
                .offset(x: 16)
        }
        .frame(height: 56)
    }
}
