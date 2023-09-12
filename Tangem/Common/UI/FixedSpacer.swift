//
//  FixedSpacer.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

/// A spacer with fixed dimensions.
struct FixedSpacer: View {
    var width: CGFloat? = nil
    var height: CGFloat? = nil
    var length: CGFloat? = nil

    var body: some View {
        Spacer(minLength: length)
            .frame(width: width, height: height)
    }
}
