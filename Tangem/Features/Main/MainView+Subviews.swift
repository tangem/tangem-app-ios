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

// [REDACTED_TODO_COMMENT]
extension MainView {
    // MARK: - RedesignedBottomOverlay

    struct RedesignedBottomOverlay: View {
        @State private var height: CGFloat?
        @State private var distance: CGFloat?

        @StateObject private var tracker: RefreshScrollViewBottomTracker

        private var params: FullPagePagerBottomOverlayParams {
            let contentHeight: CGFloat
            let isActive: Bool

            if let distance, let height {
                contentHeight = height
                isActive = distance >= height
            } else {
                contentHeight = .zero
                isActive = false
            }

            return FullPagePagerBottomOverlayParams(
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
            pageBuilder.bottomOverlay
                .readGeometry(\.size.height) { height = $0 }
                .onReceive(tracker.distancePublisher) { distance = $0 }
        }
    }
}
