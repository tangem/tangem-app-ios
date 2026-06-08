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
    let onHeaderMinYChanged: (CGFloat) -> Void

    let totalPages: Int
    let currentIndex: Int

    var body: some View {
        RefreshScrollView(stateObject: refreshScrollViewStateObject, contentSettings: .simpleContent) {
            VStack(spacing: .zero) {
                header
                    .padding(.top, Paddings.headerTop)

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
        .onGeometryChange(
            for: CGFloat.self,
            of: { proxy in
                proxy.frame(in: .global).minY
            },
            action: onHeaderMinYChanged
        )
    }

    private var content: some View {
        pageBuilder.content
            .safeAreaInset(edge: .bottom, spacing: 0) {
//                Color.clear.frame(height: overlayCollapsedHeight)
            }
    }
}

extension UserWalletView {
    enum Paddings {
        static let headerTop = CGFloat.unit(.x13)
    }
}
