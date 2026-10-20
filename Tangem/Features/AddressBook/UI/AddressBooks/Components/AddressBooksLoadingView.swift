//
//  AddressBooksLoadingView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct AddressBooksLoadingView: View {
    private let placeholders = (0 ..< Constants.rowCount).map(Placeholder.init)

    var body: some View {
        GroupedSection(placeholders, isLazy: false) { _ in
            AddressBookContactSkeletonView()
        }
        .separatorStyle(.none)
        .cornerRadius(24)
        .horizontalPadding(0)
    }
}

private extension AddressBooksLoadingView {
    struct Placeholder: Identifiable {
        let id: Int
    }

    enum Constants {
        static let rowCount = 3
    }
}

struct AddressBookContactSkeletonView: View {
    @ScaledMetric private var scaleFactor: CGFloat = 1

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Shimmer()
                .variant(.custom(width: 40 * scaleFactor, height: 40 * scaleFactor))

            VStack(alignment: .leading, spacing: 4) {
                Shimmer()
                    .variant(.custom(width: 143 * scaleFactor, height: 16 * scaleFactor))

                Shimmer()
                    .variant(.custom(width: 86 * scaleFactor, height: 12 * scaleFactor))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
    }
}

// MARK: - Previews

#Preview {
    GroupedScrollView(contentType: .lazy(spacing: 8)) {
        AddressBooksLoadingView()
    }
    .background(DesignSystem.Color.bgBase.edgesIgnoringSafeArea(.all))
}
