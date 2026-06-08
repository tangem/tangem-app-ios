//
//  UserWalletView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import func TangemFoundation.clamp
import TangemUI

struct UserWalletView: View {
    let pageBuilder: MainUserWalletPageBuilder
    let refreshScrollViewStateObject: RefreshScrollViewStateObject
    let onHeaderMinYChanged: (CGFloat) -> Void

    let totalPages: Int
    let currentIndex: Int

    @State private var headerScale: CGFloat = 1
    @State private var headerOpacity: CGFloat = 1
    @State private var safeAreaInsetsTop = CGFloat.zero

    @ScaledMetric private var headerBalanceTextHeight = CGFloat.unit(.x12)

    var body: some View {
        RefreshScrollView(stateObject: refreshScrollViewStateObject, contentSettings: .simpleContent) {
            VStack(spacing: .zero) {
                headerAnchorSpacer
                header
                content
            }
        }
        .onGeometryChange(for: CGFloat.self, of: \.safeAreaInsets.top) { safeAreaInsetsTop in
            self.safeAreaInsetsTop = safeAreaInsetsTop
        }
    }

    private var headerAnchorSpacer: some View {
        Spacer(minLength: .zero)
            .frame(height: Paddings.headerTop)
            .onGeometryChange(
                for: CGFloat.self,
                of: { proxy in
                    proxy.frame(in: .global).minY
                },
                action: { headerMinY in
                    onHeaderMinYChanged(headerMinY)

                    let startY = safeAreaInsetsTop
                    let endY = headerBalanceTextHeight + Paddings.headerTop
                    let progress = clamp((startY - headerMinY) / (startY + endY), min: 0, max: 1)

                    headerOpacity = headerOpacity(for: progress)
                    headerScale = headerScale(for: progress)
                }
            )
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
        .scaleEffect(headerScale)
        .opacity(headerOpacity)
    }

    private var content: some View {
        pageBuilder.content
            .safeAreaInset(edge: .bottom, spacing: 0) {
//                Color.clear.frame(height: overlayCollapsedHeight)
            }
    }

    private func headerOpacity(for progress: CGFloat) -> CGFloat {
        1 - progress * 0.8
    }

    private func headerScale(for progress: CGFloat) -> CGFloat {
        1 - progress * 0.1
    }
}

extension UserWalletView {
    private enum Paddings {
        static let headerTop = CGFloat.unit(.x13)
    }
}
