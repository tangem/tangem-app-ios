//
//  View+presentationBackports.swift
//  TangemUIUtils
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

public extension View {
    @ViewBuilder
    func presentationCornerRadiusBackport(_ cornerRadius: CGFloat) -> some View {
        if #available(iOS 16.4, *) {
            presentationCornerRadius(cornerRadius)
        } else {
            presentationConfiguration { controller in
                controller.preferredCornerRadius = cornerRadius
            }
        }
    }
}
