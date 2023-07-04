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
    let overlayViewAdditionalVerticalInset: CGFloat
    let tokenListHeaderViewTopInset: CGFloat

    var body: some View {
        OrganizeTokensHeaderView(viewModel: viewModel)
            .readGeometry(\.size.height) { height in
                scrollViewTopContentInset.wrappedValue = height
                    + overlayViewAdditionalVerticalInset
                    + tokenListHeaderViewTopInset
            }
            .padding(.top, tokenListHeaderViewTopInset)
            .padding(.bottom, overlayViewAdditionalVerticalInset)
            .padding(.horizontal, contentHorizontalInset)
    }
}
