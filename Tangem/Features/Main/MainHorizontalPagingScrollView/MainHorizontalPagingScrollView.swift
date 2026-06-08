//
//  MainHorizontalPagingScrollView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemFoundation
import TangemUI

struct MainHorizontalPagingScrollView: View {
    let userWalletPageBuilders: [MainUserWalletPageBuilder]
    let selectedCardIndex: Binding<Int>
    let refreshScrollViewStateObject: RefreshScrollViewStateObject
    let isHorizontalScrollDisabled: Bool
    let scanQRCodeAction: () -> Void
    let detailsAction: () -> Void

    @State private var userWalletIndexToHeaderMinY = [Int: CGFloat]()
    @State private var selectedUserWalletHeaderMinY = CGFloat.zero
    @State private var safeAreaInsetsTop = CGFloat.zero

    var body: some View {
        horizontalScrollView
            .northernLightsBackground(backgroundColor: .Tangem.Surface.level2, opacity: northernLightsBackgroundOpacity)
            .redesignToolbar(
                pageBuilder: userWalletPageBuilders[selectedCardIndex.wrappedValue],
                principalContentOpacity: navigationBarBalanceOpacity,
                principalContentOffset: navigationBarBalanceOffsetY,
                scanQRCodeAction: scanQRCodeAction,
                detailsAction: detailsAction
            )
            .onGeometryChange(for: CGFloat.self, of: \.safeAreaInsets.top) { safeAreaInsetsTop in
                self.safeAreaInsetsTop = safeAreaInsetsTop
            }
//            .onChange(of: selectedCardIndex.wrappedValue) { _ in
//                selectedUserWalletHeaderMinY = safeAreaInsetsTop
//            }
//            .animation(.default, value: selectedUserWalletHeaderMinY)
    }

    @ViewBuilder
    private var horizontalScrollView: some View {
        if #available(iOS 17.0, *) {
            HorizontalPagingScrollView(
                userWalletPageBuilders: userWalletPageBuilders,
                selectedCardIndex: selectedCardIndex,
                refreshScrollViewStateObject: refreshScrollViewStateObject,
                headerMinY: $selectedUserWalletHeaderMinY,
                isHorizontalScrollDisabled: isHorizontalScrollDisabled
            )
        } else {
            EmptyView()
        }
    }

    // [REDACTED_TODO_COMMENT]

    private var navigationBarBalanceOpacity: CGFloat {
        let progress = clamp(
            -selectedUserWalletHeaderMinY / Sizes.headerBalanceTextHeight,
            min: 0,
            max: 1
        )

        return pow(progress, 3)
    }

    private var navigationBarBalanceOffsetY: CGFloat {
        let progress = clamp(
            -selectedUserWalletHeaderMinY / Sizes.headerBalanceTextHeight,
            min: 0,
            max: 1
        )

        let maximumTravelDistance: CGFloat = 16

        return (1 - pow(progress, 3)) * maximumTravelDistance
    }

    private var northernLightsBackgroundOpacity: CGFloat {
        let startY = safeAreaInsetsTop + UserWalletView.Paddings.headerTop
        let endY = -Sizes.headerBalanceTextHeight

        let progress = clamp(
            (startY - selectedUserWalletHeaderMinY) / (startY - endY),
            min: 0,
            max: 1
        )

        return 1 - pow(progress, 1.25)
    }
}

extension MainHorizontalPagingScrollView {
    @available(iOS 17.0, *)
    private struct HorizontalPagingScrollView: View {
        let userWalletPageBuilders: [MainUserWalletPageBuilder]
        let selectedCardIndex: Binding<Int>
        let refreshScrollViewStateObject: RefreshScrollViewStateObject
        let headerMinY: Binding<CGFloat>
        let scrollPositionID: Binding<Int?>
        let isHorizontalScrollDisabled: Bool

        init(
            userWalletPageBuilders: [MainUserWalletPageBuilder],
            selectedCardIndex: Binding<Int>,
            refreshScrollViewStateObject: RefreshScrollViewStateObject,
            headerMinY: Binding<CGFloat>,
            isHorizontalScrollDisabled: Bool
        ) {
            self.userWalletPageBuilders = userWalletPageBuilders
            self.selectedCardIndex = selectedCardIndex
            self.refreshScrollViewStateObject = refreshScrollViewStateObject
            self.headerMinY = headerMinY
            scrollPositionID = Binding(selectedCardIndex)
            self.isHorizontalScrollDisabled = isHorizontalScrollDisabled
        }

        var body: some View {
            ScrollView(.horizontal) {
                LazyHStack(spacing: .zero) {
                    ForEach(indexed: userWalletPageBuilders.indexed()) { index, userWalletPageBuilder in
                        UserWalletView(
                            pageBuilder: userWalletPageBuilder,
                            refreshScrollViewStateObject: refreshScrollViewStateObject,
                            headerMinY: headerMinY,
                            totalPages: userWalletPageBuilders.count,
                            currentIndex: selectedCardIndex.wrappedValue
                        )
                        .containerRelativeFrame(.horizontal)
                        .id(index)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: scrollPositionID)
            .scrollDisabled(isHorizontalScrollDisabled)
        }
    }
}

extension MainHorizontalPagingScrollView {
    private enum Sizes {
        static let headerBalanceTextHeight: CGFloat = 48.0
    }
}

private extension View {
    func redesignToolbar(
        pageBuilder: MainUserWalletPageBuilder,
        principalContentOpacity: CGFloat,
        principalContentOffset: CGFloat,
        scanQRCodeAction: @escaping () -> Void,
        detailsAction: @escaping () -> Void
    ) -> some View {
        modifier(
            MainViewRedesignToolbar(
                principalContent: {
                    pageBuilder.navigation
                        .opacity(principalContentOpacity)
                        .offset(y: principalContentOffset)
                },
                scanQRCodeAction: scanQRCodeAction,
                detailsAction: detailsAction
            )
        )
    }
}
