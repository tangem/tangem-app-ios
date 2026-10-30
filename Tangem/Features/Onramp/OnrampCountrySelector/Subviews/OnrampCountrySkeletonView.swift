//
//  OnrampCountrySkeletonView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct OnrampCountrySkeletonView: View {
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Shimmer().variant(.custom(width: 36, height: 36))

            Shimmer().variant(.custom(width: 70, height: 12, cornerRadius: 3))
        }
        .padding(.vertical, 14)
    }
}
