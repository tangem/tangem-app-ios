//
//  VIew+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

extension View {
    @ViewBuilder func ignoresKeyboard() -> some View {
        if #available(iOS 14.0, *) {
            self.ignoresSafeArea(.keyboard)
        } else {
            self
        }
    }
}

extension View {
	func toAnyView() -> AnyView {
		AnyView(self)
	}
    
    @ViewBuilder func tintCompat(_ color: Color) -> some View {
        if #available(iOS 15.0, *) {
            self.tint(color)
        } else {
            self
        }
    }
    
    @ViewBuilder func toggleStyleCompat(_ color: Color) -> some View {
        if #available(iOS 15.0, *) {
            self.tint(color)
        } else if #available(iOS 14.0, *) {
            self.toggleStyle(SwitchToggleStyle(tint: color))
        } else {
            self
        }
    }
}
