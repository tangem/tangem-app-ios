//
//  OrganizeTokensListHeader.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct OrganizeTokensListHeader: View {
    let viewModel: OrganizeTokensHeaderViewModel
    let horizontalInset: CGFloat
    let bottomInset: CGFloat

    var body: some View {
        OrganizeTokensHeaderView(viewModel: viewModel)
            .padding(.top, 8.0)
            .padding(.bottom, bottomInset)
            .padding(.horizontal, horizontalInset)
    }
}

// MARK: - Constants

private extension OrganizeTokensListHeader {
    private enum Constants {
        static let topInset = 4.0
    }
}
