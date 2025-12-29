//
//  YieldAvailableNotificationView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemUI
import TangemAssets
import TangemAccessibilityIdentifiers

struct YieldAvailableNotificationView: View {
    @ObservedObject
    var viewModel: YieldAvailableNotificationViewModel

    // MARK: - View Body

    var body: some View {
        content
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(Colors.Background.primary)
            .cornerRadiusContinuous(14)
            .onAppear(perform: viewModel.onAppear)
    }

    // MARK: - Sub Views

    var content: some View {
        VStack(alignment: .leading, spacing: 14) {
            messageIconContent
            button
        }
    }

    @ViewBuilder
    private var button: some View {
        MainButton(
            title: Localization.commonLearnMore,
            style: .secondary,
            size: .notification,
            action: { viewModel.onGetStartedTap() }
        )
        .accessibilityIdentifier(CommonUIAccessibilityIdentifiers.yieldModuleNotificationButton)
    }

    private var messageIconContent: some View {
        HStack(spacing: 12) {
            icon

            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.makeTitleText())
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier(CommonUIAccessibilityIdentifiers.yieldModuleNotificationTitle)

                Text(Localization.yieldModuleTokenDetailsEarnNotificationDescription)
                    .multilineTextAlignment(.leading)
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                    .infinityFrame(axis: .horizontal, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier(CommonUIAccessibilityIdentifiers.yieldModuleNotificationMessage)
            }
        }
        .infinityFrame(axis: .horizontal, alignment: .leading)
        .padding(.trailing, 20)
    }

    private var icon: some View {
        Assets.YieldModule.yieldModuleLogo.image
            .resizable()
            .frame(size: .init(bothDimensions: 36))
            .accessibilityIdentifier(CommonUIAccessibilityIdentifiers.yieldModuleNotificationIcon)
    }
}
