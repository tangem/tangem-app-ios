//
//  SendYieldNoticeView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemUI
import TangemAssets

struct SendYieldNoticeView: View {
    let viewModel: SendYieldNoticeStepViewModel

    var body: some View {
        YieldModuleBottomSheetContainerView(
            title: Localization.yieldModuleAlertTitle(viewModel.currencySymbol),
            subtitle: Localization.yieldModuleAlertDescription,
            button: MainButton(settings: .init(title: Localization.commonGotIt, style: .secondary, action: viewModel.didTapButton)),
            header: { BottomSheetHeaderView(title: "", trailing: { CircleButton.close { viewModel.didTapClose() }}) },
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
