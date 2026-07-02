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
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            TangemShimmer()
                .variant(.custom(width: 40, height: 40))

            VStack(alignment: .leading, spacing: 4) {
                TangemShimmer()
                    .variant(.custom(width: 143, height: 16))

                TangemShimmer()
                    .variant(.custom(width: 86, height: 12))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
    }
}

// MARK: - Previews

#if DEBUG
struct AddressBooksLoadingView_Previews: PreviewProvider {
    static var previews: some View {
        GroupedScrollView(contentType: .lazy(spacing: 8)) {
            AddressBooksLoadingView()
        }
        .background(DesignSystem.Color.bgBase.edgesIgnoringSafeArea(.all))
    }
}
#endif // DEBUG
