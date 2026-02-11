//
//  View_withCloseButton.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

public extension View {
    func withCloseButton(
        placement: ToolbarItemPlacement = .topBarLeading,
        style: CloseButtonStyle = .text,
        action: @escaping () -> Void
    ) -> some View {
        toolbar {
            switch style {
            case .text:
                ToolbarItem(placement: placement) {
                    CloseTextButton(action: action)
                }

            case .icon:
                NavigationToolbarButton.close(placement: placement, action: action)
            }
        }
    }
}

public enum CloseButtonStyle {
    case text
    case icon
}
