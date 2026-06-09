//
//  MainHorizontalPagingScrollView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import func TangemFoundation.clamp
import TangemUI

struct MainHorizontalPagingScrollView: View {
    let userWalletPageBuilders: [MainUserWalletPageBuilder]
    let selectedCardIndex: Binding<Int>
    let refreshScrollViewStateObject: RefreshScrollViewStateObject
    let isPullToRefreshRunning: Bool
    let scanQRCodeAction: () -> Void
    let detailsAction: () -> Void

    @State private var userWalletIndexToScrollAdjustedValues = [Int: ScrollAdjustedValues]()
    @State private var safeAreaInsetsTop = CGFloat.zero

    @ScaledMetric private var headerBalanceTextHeight = CGFloat.unit(.x12)

    @StateObject private var scrollDetector = ScrollDetector()

    var body: some View {
        horizontalScrollView
            .northernLightsBackground(
                backgroundColor: .Tangem.Surface.level2,
                opacity: selectedUserWalletScrollAdjustedValues.northernLightsBackgroundOpacity
            )
            .redesignToolbar(
                pageBuilder: userWalletPageBuilders[selectedCardIndex.wrappedValue],
                principalContentOpacity: selectedUserWalletScrollAdjustedValues.navigationBarBalanceOpacity,
                principalContentOffset: selectedUserWalletScrollAdjustedValues.navigationBarBalanceOffsetY,
                scanQRCodeAction: scanQRCodeAction,
                detailsAction: detailsAction
            )
            .onGeometryChange(for: CGFloat.self, of: \.safeAreaInsets.top) { safeAreaInsetsTop in
                self.safeAreaInsetsTop = safeAreaInsetsTop
            }
            .environmentObject(scrollDetector)
            .animation(.default, value: selectedCardIndex.wrappedValue)
    }

    @ViewBuilder
    private var horizontalScrollView: some View {
        if #available(iOS 17.0, *) {
            HorizontalPagingScrollView(
                userWalletPageBuilders: userWalletPageBuilders,
                selectedCardIndex: selectedCardIndex,
                refreshScrollViewStateObject: refreshScrollViewStateObject,
                onHeaderMinYChanged: { index, headerMinY in
                    var scrollAdjustedValues = userWalletIndexToScrollAdjustedValues[index, default: .initial]

                    let navigationBarProgress = clamp(-headerMinY / headerBalanceTextHeight, min: 0, max: 1)

                    scrollAdjustedValues.navigationBarBalanceOpacity = navigationBarBalanceOpacity(for: navigationBarProgress)
                    scrollAdjustedValues.navigationBarBalanceOffsetY = navigationBarBalanceOffsetY(for: navigationBarProgress)
                    scrollAdjustedValues.northernLightsBackgroundOpacity = northernLightsBackgroundOpacity(for: headerMinY)

                    userWalletIndexToScrollAdjustedValues[index] = scrollAdjustedValues
                },
                isHorizontalScrollDisabled: isHorizontalScrollDisabled
            )
        } else {
            EmptyView()
        }
    }

    private var isHorizontalScrollDisabled: Bool {
        isPullToRefreshRunning || selectedUserWalletScrollAdjustedValues.navigationBarBalanceOpacity >= 1
    }

    private var selectedUserWalletScrollAdjustedValues: ScrollAdjustedValues {
        userWalletIndexToScrollAdjustedValues[selectedCardIndex.wrappedValue, default: .initial]
    }

    private func navigationBarBalanceOpacity(for progress: CGFloat) -> CGFloat {
        pow(progress, 3)
    }

    private func navigationBarBalanceOffsetY(for progress: CGFloat) -> CGFloat {
        (1 - pow(progress, 3)) * Sizes.navigationBalanceMaxYOffset
    }

    private func northernLightsBackgroundOpacity(for headerMinY: CGFloat) -> CGFloat {
        let startY = safeAreaInsetsTop
        let endY = headerBalanceTextHeight
        let progress = clamp((startY - headerMinY) / (startY + endY), min: 0, max: 1)

        return 1 - pow(progress, 1.25)
    }
}

extension MainHorizontalPagingScrollView {
    @available(iOS 17.0, *)
    private struct HorizontalPagingScrollView: View {
        let userWalletPageBuilders: [MainUserWalletPageBuilder]
        let selectedCardIndex: Binding<Int>
        let refreshScrollViewStateObject: RefreshScrollViewStateObject
        let onHeaderMinYChanged: (Int, CGFloat) -> Void
        let scrollPositionID: Binding<Int?>
        let isHorizontalScrollDisabled: Bool

        init(
            userWalletPageBuilders: [MainUserWalletPageBuilder],
            selectedCardIndex: Binding<Int>,
            refreshScrollViewStateObject: RefreshScrollViewStateObject,
            onHeaderMinYChanged: @escaping (Int, CGFloat) -> Void,
            isHorizontalScrollDisabled: Bool
        ) {
            self.userWalletPageBuilders = userWalletPageBuilders
            self.selectedCardIndex = selectedCardIndex
            self.refreshScrollViewStateObject = refreshScrollViewStateObject
            self.onHeaderMinYChanged = onHeaderMinYChanged
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
                            onHeaderMinYChanged: { headerMinY in
                                onHeaderMinYChanged(index, headerMinY)
                            },
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
        static let navigationBalanceMaxYOffset: CGFloat = 16.0
    }

    private struct ScrollAdjustedValues: Equatable {
        var navigationBarBalanceOpacity: CGFloat
        var navigationBarBalanceOffsetY: CGFloat
        var northernLightsBackgroundOpacity: CGFloat

        static let initial = ScrollAdjustedValues(
            navigationBarBalanceOpacity: 1,
            navigationBarBalanceOffsetY: 0,
            northernLightsBackgroundOpacity: 1
        )
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
