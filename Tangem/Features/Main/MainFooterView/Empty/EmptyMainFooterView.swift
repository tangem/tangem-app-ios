//
//  EmptyMainFooterView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUIUtils
import TangemUI

struct EmptyMainFooterView: View {
    private var footerHeight: CGFloat {
        // Different padding on devices with/without notch
        let bottomSafeAreaInset = UIApplication.safeAreaInsets.bottom
        return bottomSafeAreaInset > 0.0 ? bottomSafeAreaInset + 6.0 : 12.0
    }

    var body: some View {
        FixedSpacer.vertical(footerHeight)
    }
}
