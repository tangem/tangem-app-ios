//
//  NFTNotificationView.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemAssets
import SwiftUI
import TangemUIUtils
import TangemFoundation

/// NOTE: This is a raw duplicate of `NotificationView` from main project
/// It is not possible to extract it to TangemUI at the moment
/// So I created this to use in-place. Should be replaced with
/// `NotificationView` when extracted
struct NFTNotificationView: View {
    let viewData: NFTNotificationViewData

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .roundedBackground(
                with: Colors.Button.disabled,
                verticalPadding: 12,
                horizontalPadding: 14
            )
    }

    private var content: some View {
        HStack(spacing: 12) {
            viewData.icon.image
                .resizable()
                .frame(size: .init(bothDimensions: 20))

            texts
        }
    }

    private var texts: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(viewData.title)
                .style(Fonts.Bold.footnote, color: Colors.Text.primary1)
            Text(viewData.subtitle)
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
        }
    }
}

#if DEBUG
#Preview {
    NFTNotificationView(
        viewData: .init(
            title: "Temporary loading problems",
            subtitle: "Some data may not load",
            icon: Assets.warningIcon
        )
    )
}
#endif
