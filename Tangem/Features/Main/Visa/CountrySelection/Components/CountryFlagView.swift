//
//  CountryFlagView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemUIUtils

struct CountryFlagView: View {
    let url: URL?

    var body: some View {
        IconView(
            url: url,
            size: CGSize(bothDimensions: Constants.side),
            cornerRadius: Constants.side / 2
        )
        .clipShape(Circle())
    }
}

// MARK: - Constants

private extension CountryFlagView {
    enum Constants {
        static let side: CGFloat = 40
    }
}
