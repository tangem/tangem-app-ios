//
//  RealAssetsWidgetView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

struct RealAssetsWidgetView: View {
    @ObservedObject var viewModel: RealAssetsWidgetViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.contentSpacing) {
            header

            RealAssetsContentView(viewModel: viewModel)
        }
    }

    private var header: some View {
        MarketsCommonWidgetHeaderView(
            headerTitle: viewModel.widgetType.headerTitle ?? "",
            headerImage: nil,
            buttonTitle: nil,
            buttonAction: nil,
            isLoadingState: viewModel.headerLoadingState
        )
    }
}

private extension RealAssetsWidgetView {
    enum Layout {
        static let contentSpacing: CGFloat = 12
    }
}
