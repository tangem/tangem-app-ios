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
}
