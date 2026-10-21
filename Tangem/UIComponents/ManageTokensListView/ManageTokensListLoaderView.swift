//
//  ManageTokensListLoaderView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct ManageTokensItemSkeletonView: View {
    var body: some View {
        HStack(spacing: 12) {
            Shimmer().variant(.custom(width: 36, height: 36))

            Shimmer().variant(.custom(width: 70, height: 12, cornerRadius: 3))

            Spacer()

            Shimmer().variant(.custom(width: 24, height: 12, cornerRadius: 3))
        }
        .padding(16)
    }
}

struct ManageTokensListLoaderView: View {
    var body: some View {
        VStack(spacing: 0) {
            ForEach(0 ..< 20) { _ in
                ManageTokensItemSkeletonView()
            }
        }
    }
}

#Preview {
    ManageTokensListLoaderView()
}
