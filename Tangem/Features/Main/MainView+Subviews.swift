//
//  MainView+Subviews.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import TangemFoundation
import TangemUI
import TangemLocalization
import TangemAccessibilityIdentifiers

extension MainView {
    // MARK: - RedesignedBottomOverlay

    struct RedesignedBottomOverlay: View {
        @State private var height: CGFloat?
        @State private var distance: CGFloat?

        @StateObject private var tracker: RefreshScrollViewBottomTracker

        private var params: FullPagePagerBottomOverlayParams {
            let contentHeight: CGFloat
            let didScrollToBottom: Bool
            let isActive: Bool

            if let distance, let height {
                contentHeight = height
                didScrollToBottom = distance >= 0
                isActive = distance >= height
            } else {
                contentHeight = .zero
                didScrollToBottom = false
                isActive = false
            }

            return FullPagePagerBottomOverlayParams(
                didScrollToBottom: didScrollToBottom,
                contentHeight: contentHeight,
                isActive: isActive
            )
        }

        private let pageBuilder: MainUserWalletPageBuilder

        init(
            refreshScrollViewInteractor: RefreshScrollViewInteractor,
            pageBuilder: MainUserWalletPageBuilder
        ) {
            self.pageBuilder = pageBuilder
            _tracker = StateObject(wrappedValue: RefreshScrollViewBottomTracker(
                scrollInteractor: refreshScrollViewInteractor
            ))
        }

        var body: some View {
            pageBuilder.makeRedesignedBottomOverlay(params)
                .readGeometry(\.size.height) { height = $0 }
                .onReceive(tracker.distancePublisher) { distance = $0 }
        }
    }
}
