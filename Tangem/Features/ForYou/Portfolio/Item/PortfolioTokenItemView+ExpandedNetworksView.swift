//
//  PortfolioTokenItemView+ExpandedNetworksView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

extension PortfolioTokenItemView {
    struct ExpandedNetworksView: View {
        let networkRows: [ForYouTokenRowData]

        var body: some View {
            VStack(spacing: 0) {
                ForEach(networkRows) { row in
                    RowView(data: row)
                }
            }
        }
    }
}
