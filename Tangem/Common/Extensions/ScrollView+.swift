//
//  ScrollView+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

extension View {
    @ViewBuilder
    func scrollDismissesKeyboardCompat(_ dismissKeyboardOnScroll: Bool) -> some View {
        if #available(iOS 16.0, *) {
            self.scrollDismissesKeyboard(dismissKeyboardOnScroll ? .immediately : .never)
        } else {
            self
        }
    }
}
