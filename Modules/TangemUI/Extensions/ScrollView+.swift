//
//  ScrollView+.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

public extension View {
    /// Backports ``View.scrollDisabled(_:)``.
    /// - Attention: No-op for iOS 15.
    /// - Parameter isDisabled: A Boolean that indicates whether scrolling is disabled.
    @available(iOS, obsoleted: 16.0, message: "Use native View.scrollDisabled(_:) instead.")
    @ViewBuilder
    func scrollDisabledBackport(_ isDisabled: Bool) -> some View {
        if #available(iOS 16.0, *) {
            scrollDisabled(isDisabled)
        } else {
            self
        }
    }
}
