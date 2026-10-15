//
//  CollectiblesDismissStyle.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

enum CollectiblesDismissStyle {
    case back
    case close

    @ViewBuilder
    func button(action: @escaping () -> Void) -> some View {
        switch self {
        case .back:
            NavigationBarButton.back(action: action)
        case .close:
            NavigationBarButton.close(action: action)
        }
    }

    func toolbarButton(placement: ToolbarItemPlacement, action: @escaping () -> Void) -> NavigationToolbarButton {
        let button: NavigationToolbarButton

        switch self {
        case .back:
            button = .back(placement: placement, action: action)
        case .close:
            button = .close(placement: placement, action: action)
        }

        return button.redesigned()
    }
}
