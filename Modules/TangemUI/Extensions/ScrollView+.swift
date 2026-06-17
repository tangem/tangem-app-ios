//
//  ScrollView+.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

public extension View {
    @ViewBuilder
    @available(iOS, obsoleted: 17.0, message: "Use native SwiftUI implementation.")
    func scrollClipDisabledBackport() -> some View {
        if #available(iOS 17.0, *) {
            scrollClipDisabled()
        } else {
            // [REDACTED_TODO_COMMENT]
            self
        }
    }
}
