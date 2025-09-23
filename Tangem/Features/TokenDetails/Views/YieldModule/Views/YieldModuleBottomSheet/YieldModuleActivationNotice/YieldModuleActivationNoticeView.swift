//
//  YieldModuleActivationNoticeView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemLocalization
import TangemAssets

struct YieldModuleActivationNoticeView: View {
    let currencySymbol: String
    let buttonAction: () -> Void
    let tokenIconInfo: TokenIconInfo

    var body: some View {
        // [REDACTED_TODO_COMMENT]
        YieldModuleBottomSheetContainerView(
            title: Localization.yieldModuleAlertTitle(currencySymbol),
            subtitle: Localization.yieldModuleAlertDescription,
            button: MainButton(settings: .init(title: Localization.commonGotIt, style: .secondary, action: buttonAction)),
            topContent: { lendingPairIcon }
        )
    }

    private var lendingPairIcon: some View {
        ZStack {
            TokenIcon(
                tokenIconInfo: tokenIconInfo,
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
