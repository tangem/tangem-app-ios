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
    let scrollViewTopContentInset: Binding<CGFloat>
    let contentHorizontalInset: CGFloat

    var body: some View {
        OrganizeTokensHeaderView(viewModel: viewModel)
            .readGeometry(transform: \.size.height) { height in
                scrollViewTopContentInset.wrappedValue = height + Constants.topInset
            }
            .padding(.top, Constants.topInset)
            .padding(.horizontal, contentHorizontalInset)
            .infinityFrame(alignment: .top)
    }
}

// MARK: - Constants

private extension OrganizeTokensListHeader {
    private enum Constants {
        static let topInset = 8.0
    }
}
