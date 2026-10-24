//
//  TokenDetailsActionRowsListView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct TokenDetailsActionRowsListView: View {
    let items: [TokenDetailsActionRowItem]

    @ScaledMetric private var rowSpacing: CGFloat = 8

    var body: some View {
        VStack(spacing: rowSpacing) {
            ForEach(items) { item in
                TokenDetailsActionRowView(item: item)
            }
        }
    }
}
