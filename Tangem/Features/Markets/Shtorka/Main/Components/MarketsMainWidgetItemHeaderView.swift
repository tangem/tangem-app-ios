//
//  MarketsMainWidgetItemHeaderView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

struct MarketsMainWidgetItemHeaderView: View {
    let title: String?

    var body: some View {
        Group {
            if let title {
                Text(title)
                    .font(.headline)
            }
        }
    }
}
