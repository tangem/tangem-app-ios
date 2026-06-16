//
//  OrganizeTokensListItemViewRedesigned.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct OrganizeTokensListItemViewRedesigned: View {
    let viewModel: OrganizeTokensListItemViewModel

    @ScaledMetric private var horizontalPadding: CGFloat = .unit(.x3)
    @ScaledMetric private var verticalPadding: CGFloat = .unit(.x3)

    var body: some View {
        TangemTokenRow(viewData: rowViewData)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .overlay(alignment: .trailing) {
                if viewModel.isDraggable {
                    OrganizeTokensDragAndDropGestureMarkView(context: .init(identifier: viewModel.id))
                        .frame(size: Constants.dragAndDropTapZoneSize)
                }
            }
    }

    private var rowViewData: TangemTokenRowViewData {
        TangemTokenRowViewData(
            id: viewModel.id,
            tokenIconInfo: viewModel.tokenIconInfo,
            name: viewModel.name,
            badge: nil,
            content: .compact(subtitle: subtitleState, trailingIcon: trailingIcon),
            hasMonochromeIcon: viewModel.hasMonochromeIcon
        )
    }

    private var subtitleState: LoadableBalanceView.State {
        if let errorMessage = viewModel.errorMessage {
            return .loaded(text: errorMessage)
        }
        return viewModel.balance
    }

    private var trailingIcon: ImageType? {
        viewModel.isDraggable ? Assets.OrganizeTokens.itemDragAndDropIcon : nil
    }
}

// MARK: - Constants

private extension OrganizeTokensListItemViewRedesigned {
    enum Constants {
        static let dragAndDropTapZoneSize = CGSize(bothDimensions: 64.0)
    }
}
