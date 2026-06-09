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
    let onContentGeometryChanged: (ScrollContentGeometry) -> Void

    let bottomOverlayHeight: CGFloat
    let contentFooterHeight: CGFloat

    let totalPages: Int
    let currentIndex: Int

    @State private var contentOffsetY = CGFloat.zero
    @State private var headerHeight = CGFloat.zero
    @State private var headerScale: CGFloat = 1
    @State private var headerOpacity: CGFloat = 1
    @ScaledMetric private var headerBalanceTextHeight = CGFloat.unit(.x12)

    @EnvironmentObject private var scrollDetector: ScrollDetector

    var body: some View {
        GeometryReader { rootGeometryProxy in
            ScrollViewReader { scrollProxy in
                RefreshScrollView(stateObject: refreshScrollViewStateObject, contentSettings: .simpleContent) {
                    VStack(spacing: .zero) {
                        headerAnchorSpacer
                        header
                        content
                        contentFooterSpacer
                        bottomOverlaySpacer
                    }
                    .onGeometryChange(
                        for: CGRect.self,
                        of: { contentGeometryProxy in
                            contentGeometryProxy.frame(in: .global)
                        },
                        action: { contentFrame in
                            handleScrollChanged(contentFrame, rootGeometryProxy)
                        }
                    )
                }
                .onChange(of: scrollDetector.isScrolling) { [oldValue = scrollDetector.isScrolling] newValue in
                    if newValue != oldValue, !newValue {
                        performVerticalScrollIfNeeded(with: scrollProxy, safeAreaInsetsTop: rootGeometryProxy.safeAreaInsets.top)
                    }
                }
            }
        }
    }

    private var headerAnchorSpacer: some View {
        Spacer(minLength: .zero)
            .frame(height: Paddings.headerTop)
            .id(HeaderScrollAnchorIdentifier.top)
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
        .onGeometryChange(for: CGFloat.self, of: \.size.height) { headerHeight in
            self.headerHeight = headerHeight
        }
        .scaleEffect(headerScale)
        .opacity(headerOpacity)
    }

    private var content: some View {
        pageBuilder.content
            .id(HeaderScrollAnchorIdentifier.bottom)
    }

    private var contentFooterSpacer: some View {
        Spacer(minLength: .zero)
            .frame(height: contentFooterHeight)
    }

    private var bottomOverlaySpacer: some View {
        Spacer(minLength: .zero)
            .frame(height: bottomOverlayHeight)
    }

    private func handleScrollChanged(_ contentFrame: CGRect, _ rootGeometryProxy: GeometryProxy) {
        let scrollViewFrameHeight = rootGeometryProxy.size.height
        let contentOffsetY = contentFrame.minY

        let didScrollToBottom = contentFrame.maxY - bottomOverlayHeight <= scrollViewFrameHeight
        onContentGeometryChanged(ScrollContentGeometry(contentOffsetY: contentOffsetY, didScrollToBottom: didScrollToBottom))

        let startY = rootGeometryProxy.safeAreaInsets.top
        let endY = headerBalanceTextHeight + Paddings.headerTop
        let progress = clamp((startY - contentOffsetY) / (startY + endY), min: 0, max: 1)

        self.contentOffsetY = contentOffsetY
        headerOpacity = headerOpacity(for: progress)
        headerScale = headerScale(for: progress)
    }

    private func performVerticalScrollIfNeeded(with scrollViewProxy: ScrollViewProxy, safeAreaInsetsTop: CGFloat) {
        let fullHeaderHeight = Paddings.headerTop + headerHeight
        let headerMaxY = contentOffsetY + fullHeaderHeight

        let screenTopIsBelowHeaderTop = safeAreaInsetsTop > contentOffsetY
        let screenTopIsAboveHeaderBottom = safeAreaInsetsTop < headerMaxY

        guard screenTopIsBelowHeaderTop, screenTopIsAboveHeaderBottom else {
            return
        }

        let hasReachedMiddlePoint = (safeAreaInsetsTop - contentOffsetY) > fullHeaderHeight / 2

        let targetAnchor: HeaderScrollAnchorIdentifier = hasReachedMiddlePoint
            ? .bottom
            : .top

        withAnimation(.spring) {
            scrollViewProxy.scrollTo(targetAnchor, anchor: .top)
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
    struct ScrollContentGeometry: Equatable {
        let contentOffsetY: CGFloat
        let didScrollToBottom: Bool
    }

    private enum Paddings {
        static let headerTop = CGFloat.unit(.x13)
    }

    private enum HeaderScrollAnchorIdentifier: Hashable {
        case top
        case bottom
    }
}
