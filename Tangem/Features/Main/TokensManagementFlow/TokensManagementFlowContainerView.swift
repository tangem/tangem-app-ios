//
//  TokensManagementFlowContainerView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct TokensManagementFlowContainerView<HeaderContent: View, MainContent: View>: View {
    // MARK: - Properties

    private let state: AnyHashable
    private let hidesHeader: Bool
    private let headerContent: HeaderContent
    private let mainContent: MainContent
    private let bottomPadding: CGFloat

    // MARK: - Init

    init(
        state: AnyHashable,
        hidesHeader: Bool = false,
        bottomPadding: CGFloat = 16,
        @ViewBuilder headerContent: () -> HeaderContent,
        @ViewBuilder mainContent: () -> MainContent
    ) {
        self.state = state
        self.hidesHeader = hidesHeader
        self.headerContent = headerContent()
        self.mainContent = mainContent()
        self.bottomPadding = bottomPadding
    }

    // MARK: - View Body

    var body: some View {
        VStack(spacing: 0) {
            if !hidesHeader {
                header
            }

            content
        }
        .animation(.contentFrameUpdate, value: state)
        .floatingSheetConfiguration { configuration in
            configuration.sheetBackgroundColor = Colors.Background.tertiary
            configuration.sheetFrameUpdateAnimation = .contentFrameUpdate
            configuration.backgroundInteractionBehavior = .consumeTouches
            configuration.verticalSwipeBehavior = .init(target: .sheet, threshold: 100)
        }
    }

    // MARK: - Sub Views

    private var header: some View {
        headerContent
            .padding(.top, Constants.headerVerticalSpacing)
            .padding(.horizontal, Constants.standardSpacing)
            .background(Colors.Background.tertiary.edgesIgnoringSafeArea(.all))
            .transition(.opacity)
            .id(state)
            .animation(.headerOpacity.delay(0.2), value: state)
    }

    private var content: some View {
        mainContent
            .padding(.top, hidesHeader ? 0 : Constants.standardSpacing)
            .padding(.bottom, bottomPadding)
            .transition(.content)
    }
}

// MARK: - Animations and Transitions

private extension AnyTransition {
    static let content = AnyTransition.asymmetric(
        insertion: .opacity.animation(.curve(.easeInOutRefined, duration: 0.3).delay(0.2)),
        removal: .opacity.animation(.curve(.easeInOutRefined, duration: 0.1))
    )
}

private extension Animation {
    static let headerOpacity = Animation.curve(.easeOutStandard, duration: 0.2)
    static let contentFrameUpdate = Animation.curve(.easeInOutRefined, duration: 0.5)
}

// MARK: - Constants

private enum Constants {
    static let standardSpacing: CGFloat = 16
    static let headerVerticalSpacing: CGFloat = 4
}
