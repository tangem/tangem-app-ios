//
//  UserWalletView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct UserWalletView: View {
    let pageBuilder: MainUserWalletPageBuilder
    let refreshScrollViewStateObject: RefreshScrollViewStateObject
    let totalPages: Int
    let currentIndex: Int

    var body: some View {
        RefreshScrollView(
            stateObject: refreshScrollViewStateObject,
            contentSettings: .simpleContent
        ) {
            VStack(spacing: .zero) {
                header
                content
            }
        }
    }

    private var header: some View {
        MainUserWalletHeader(
            model: MainUserWalletHeaderModel(
                headerViewModel: pageBuilder.headerModel,
                actionButtonsViewModel: pageBuilder.actionButtonsViewModel,
                paginationState: totalPages > 1
                    ? MainUserWalletHeaderModel.PaginationState(totalPages: totalPages, currentIndex: currentIndex)
                    : nil
            )
        )
    }

    private var content: some View {
        pageBuilder.content
            .safeAreaInset(edge: .bottom, spacing: 0) {
//                Color.clear.frame(height: overlayCollapsedHeight)
            }
    }
}
