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

    var body: some View {
        OrganizeTokensHeaderView(viewModel: viewModel)
            .readGeometry(transform: \.size.height) { height in
                scrollViewTopContentInset.wrappedValue = height + overlayViewAdditionalVerticalInset + 8.0
            }
            .padding(.top, 8.0)
            .padding(.horizontal, contentHorizontalInset)
            .infinityFrame(alignment: .top)
    }
}
