//
//  FeedSearchRecentTokenView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct FeedSearchRecentTokenView: View {
    let token: FeedRecentToken
    let onTap: () -> Void

    var body: some View {
        SwiftUI.Button {
            onTap()
        } label: {
            VStack(spacing: Constants.captionSpacing) {
                TokenIconV2(tokenIconInfo: token.icon, size: Constants.iconSize)

                Text(token.caption)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(Constants.captionLineLimit)
            }
            .frame(width: Constants.width)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Constants

private extension FeedSearchRecentTokenView {
    enum Constants {
        static let iconSize = TokenIconV2.Size.size44
        static let width: CGFloat = 76
        static let captionSpacing: CGFloat = 8
        static let captionLineLimit = 2
    }
}
