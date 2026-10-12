//
//  SheetScrollTouchModifier.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

struct SheetScrollTouchModifier: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
        } else if #available(iOS 18.0, *) {
            // iOS 18 can release a button as a tap after the sheet takes over its drag; a simultaneous tap recognizer restores the cancellation.
            content.simultaneousGesture(TapGesture())
        } else {
            content
        }
    }
}
