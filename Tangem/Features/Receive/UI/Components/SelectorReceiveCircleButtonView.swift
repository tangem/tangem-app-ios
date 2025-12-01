//
//  SelectorReceiveCircleButtonView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

struct SelectorReceiveCircleButtonView: View {
    private let actionType: ActionType

    init(actionType: ActionType) {
        self.actionType = actionType
    }

    var body: some View {
        actionType
            .asset
            .renderingMode(.template)
            .resizable()
            .frame(size: .init(bothDimensions: 20))
            .foregroundStyle(Colors.Icon.informative)
            .padding(Layout.paddingIcon)
            .background(
                Circle()
                    .fill(Colors.Button.secondary)
            )
            .padding(Layout.paddingIconCircle)
    }
}

extension SelectorReceiveCircleButtonView {
    enum ActionType {
        case copy
        case share

        var asset: Image {
            switch self {
            case .copy: return Assets.Receive.copyButtonIcon.image
            case .share: return Assets.Receive.shareButtonIcon.image
            }
        }
    }
}

// MARK: - Layout

private extension SelectorReceiveCircleButtonView {
    enum Layout {
        static let paddingIcon: CGFloat = 8
        static let paddingIconCircle: CGFloat = 2
    }
}
