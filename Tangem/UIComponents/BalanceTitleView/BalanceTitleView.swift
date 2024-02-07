//
//  BalanceTitleView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct BalanceTitleView: View {
    let balance: AttributedStringParameters
    let isLoading: Bool

    var body: some View {
        SensitiveText(balance)
            .multilineTextAlignment(.leading)
            .truncationMode(.middle)
            .skeletonable(isShown: isLoading, size: .init(width: 102, height: 24), radius: 6)
    }
}
