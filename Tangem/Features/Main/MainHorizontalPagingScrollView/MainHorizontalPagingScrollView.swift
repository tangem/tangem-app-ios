//
//  MainHorizontalPagingScrollView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct MainHorizontalPagingScrollView: View {
    let userWalletPageBuilders: [MainUserWalletPageBuilder]
    let selectedCardIndex: Binding<Int>
    let refreshScrollViewStateObject: RefreshScrollViewStateObject
    let isHorizontalScrollDisabled: Bool
    let scanQRCodeAction: () -> Void
    let detailsAction: () -> Void

    var body: some View {
        horizontalScrollView
            .redesignToolbar(
                pageBuilder: userWalletPageBuilders[selectedCardIndex.wrappedValue],
                scanQRCodeAction: scanQRCodeAction,
                detailsAction: detailsAction
            )
            .northernLightsBackground(
                backgroundColor: .Tangem.Surface.level2,
                opacity: 1 // clamp(2 * headerHeightRatio - 1, min: 0, max: 1)
            )
//            .animation(.default, value: headerHeightRatio)
    }

    @ViewBuilder
    private var horizontalScrollView: some View {
        if #available(iOS 17.0, *) {
            HorizontalPagingScrollView(
                userWalletPageBuilders: userWalletPageBuilders,
                selectedCardIndex: selectedCardIndex,
                refreshScrollViewStateObject: refreshScrollViewStateObject,
                isHorizontalScrollDisabled: isHorizontalScrollDisabled
            )
        } else {}
    }
}

extension MainHorizontalPagingScrollView {
    @available(iOS 17.0, *)
    @available(iOS, obsoleted: 18.0, message: "Use this implementation as the only one.")
    private struct HorizontalPagingScrollView: View {
        let userWalletPageBuilders: [MainUserWalletPageBuilder]
        let selectedCardIndex: Binding<Int>
        let refreshScrollViewStateObject: RefreshScrollViewStateObject
        let scrollPositionID: Binding<Int?>
        let isHorizontalScrollDisabled: Bool

        init(
            userWalletPageBuilders: [MainUserWalletPageBuilder],
            selectedCardIndex: Binding<Int>,
            refreshScrollViewStateObject: RefreshScrollViewStateObject,
            isHorizontalScrollDisabled: Bool
        ) {
            self.userWalletPageBuilders = userWalletPageBuilders
            self.selectedCardIndex = selectedCardIndex
            self.refreshScrollViewStateObject = refreshScrollViewStateObject
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

private extension View {
    func redesignToolbar(
        pageBuilder: MainUserWalletPageBuilder,
        scanQRCodeAction: @escaping () -> Void,
        detailsAction: @escaping () -> Void
    ) -> some View {
        modifier(
            MainViewRedesignToolbar(
                principalContent: pageBuilder.navigation,
                scanQRCodeAction: scanQRCodeAction,
                detailsAction: detailsAction
            )
        )
    }
}
