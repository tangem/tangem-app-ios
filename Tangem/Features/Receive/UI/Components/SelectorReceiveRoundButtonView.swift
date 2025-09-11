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

struct SelectorReceiveRoundButtonView: View {
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

extension SelectorReceiveRoundButtonView {
    enum ActionType {
        case copy
        case qr

        var asset: Image {
            switch self {
            case .copy: return Assets.copyNew.image
            case .qr: return Assets.qrNew.image
            }
        }
    }
}

// MARK: - Layout

private extension SelectorReceiveRoundButtonView {
    enum Layout {
        static let paddingIcon: CGFloat = 8
        static let paddingIconCircle: CGFloat = 2
    }
}
