//
//  PresentationGlassViewModifier.swift
//  TangemUIUtils
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import UIKit

public extension View {
    /// On iOS 26.1+, hides the glass the system draws under a sheet, so only its presentation background stays.
    /// Removing the modifier doesn't restore the glass, so keep it applied for the whole presentation.
    @ViewBuilder
    func presentationGlassHidden() -> some View {
        if #available(iOS 26.1, *) {
            // Set on the controller, as SwiftUI does for a material background: an effect on the detents switches the
            // sheet to scaled insets, and an interrupted drag leaves its content clipped to a stale height.
            // SwiftUI may reset the effect, so it is reapplied on layout.
            presentationConfiguration { sheet in
                if sheet.backgroundEffect == nil {
                    sheet.backgroundEffect = UIColorEffect(color: .clear)
                }
            }
        } else {
            self
        }
    }
}
