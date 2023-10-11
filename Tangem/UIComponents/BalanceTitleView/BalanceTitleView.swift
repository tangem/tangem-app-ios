//
//  BalanceTitleView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct BalanceTitleView: View {
    let balance: NSAttributedString
    let isLoading: Bool

    var body: some View {
        SensitiveText(balance)
            .multilineTextAlignment(.leading)
            .truncationMode(.middle)
            .scaledToFit()
            .minimumScaleFactor(0.5)
            .skeletonable(isShown: isLoading, size: .init(width: 102, height: 24), radius: 6)
            .style(Fonts.Bold.title1, color: Colors.Text.primary1)
            .frame(minHeight: 34)
    }
}
