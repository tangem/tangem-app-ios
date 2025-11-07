//
//  SelectorReceiveRoundButtonView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

struct SelectorReceiveRoundButtonView: View {
    private let actionType: ActionType

    init(actionType: ActionType) {
        self.actionType = actionType
    }

    var body: some View {
        HStack(alignment: .center, spacing: Layout.horizontalSpacing) {
            actionType
                .asset
                .renderingMode(.template)
                .resizable()
                .frame(size: .init(bothDimensions: Layout.iconSize))
                .foregroundStyle(Colors.Icon.primary1)

            Text(actionType.title)
                .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)
        }
        .padding(.horizontal, Layout.horizontalPadding)
        .padding(.vertical, Layout.verticalPadding)
        .background(
            RoundedRectangle(cornerRadius: Layout.cornerRadius)
                .fill(Colors.Button.secondary)
        )
    }
}

extension SelectorReceiveRoundButtonView {
    enum ActionType {
        case copy
        case share

        var asset: Image {
            switch self {
            case .copy: return Assets.Receive.copyButtonIcon.image
            case .share: return Assets.Receive.shareButtonIcon.image
            }
        }

        var title: String {
            switch self {
            case .copy: return Localization.commonCopy
            case .share: return Localization.commonShare
            }
        }
    }
}

// MARK: - Layout

private extension SelectorReceiveRoundButtonView {
    enum Layout {
        static let horizontalSpacing: CGFloat = 6
        static let horizontalPadding: CGFloat = 12
        static let verticalPadding: CGFloat = 8
        static let cornerRadius: CGFloat = 24
        static let iconSize: CGFloat = 20
    }
}
