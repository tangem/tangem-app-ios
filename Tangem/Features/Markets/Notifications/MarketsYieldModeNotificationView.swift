//
//  MarketsYieldModeNotificationView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization

struct MarketsYieldModeNotificationView: View {
    private let openAction: () -> Void
    private let closeAction: () -> Void

    init(openAction: @escaping () -> Void, closeAction: @escaping () -> Void) {
        self.openAction = openAction
        self.closeAction = closeAction
    }

    var body: some View {
        ZStack(alignment: .top) {
            Button(action: openAction) {
                messageIconContent
            }

            closeButton
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Colors.Background.stakingNotification)
                .background(Colors.Background.stakingNotification)
        )
        .cornerRadiusContinuous(14)
        .padding(.horizontal, 16)
        .padding(.top, 2)
        .padding(.bottom, 15)
    }

    private var messageIconContent: some View {
        HStack(spacing: 12) {
            Assets.yieldNotificationIcon.image

            VStack(alignment: .leading, spacing: 4) {
                Text(Localization.marketsYieldSupplyBannerTitle)
                    .multilineTextAlignment(.leading)
                    .style(Fonts.Bold.footnote, color: Colors.Text.primary1)
                    .fixedSize(horizontal: false, vertical: true)

                Text(descriptionString)
                    .multilineTextAlignment(.leading)
            }
        }
        .infinityFrame(axis: .horizontal, alignment: .leading)
        .padding(.trailing, 20)
    }

    private var whatIsStakingText: AttributedString {
        var result = AttributedString(Localization.marketsYieldSupplyBannerDescription(""))
        result.font = Fonts.Regular.caption1
        result.foregroundColor = Colors.Text.secondary
        return result
    }

    private var showMoreText: AttributedString {
        var result = AttributedString(Localization.commonShowMore)
        result.font = Fonts.Bold.caption1
        result.foregroundColor = Colors.Text.accent
        return result
    }

    private var descriptionString: AttributedString {
        whatIsStakingText + showMoreText
    }

    private var closeButton: some View {
        HStack {
            Spacer()

            Button(action: closeAction) {
                Assets.cross.image
                    .foregroundColor(Colors.Icon.informative)
            }
        }
        .padding(.top, -4)
        .padding(.trailing, -6)
    }
}
