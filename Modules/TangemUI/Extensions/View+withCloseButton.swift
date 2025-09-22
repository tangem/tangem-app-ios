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
            ToolbarItem(placement: placement) {
                switch style {
                case .text:
                    CloseButton(dismiss: action)
                case .crossImage:
                    CircleButton.close(action: action)
                }
            }
        }
    }
}

public enum CloseButtonStyle {
    case text
    case crossImage
}
