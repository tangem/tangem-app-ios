//
//  FeeSelectorBottomSheetContainerView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemUIUtils

struct FeeSelectorBottomSheetContainerView<HeaderContent: View, DescriptionContent: View, MainContent: View>: View {
    // MARK: - UI

    private let state: AnyHashable
    private let headerContent: HeaderContent
    private let descriptionContent: DescriptionContent
    private let mainContent: MainContent
    private let button: MainButton?

    // MARK: - Init

    init(
        state: AnyHashable,
        button: MainButton?,
        @ViewBuilder headerContent: () -> HeaderContent = { EmptyView() },
        @ViewBuilder descriptionContent: () -> DescriptionContent = { EmptyView() },
        @ViewBuilder mainContent: () -> MainContent = { EmptyView() }
    ) {
        self.state = state
        self.headerContent = headerContent()
        self.descriptionContent = descriptionContent()
        self.mainContent = mainContent()
        self.button = button
    }

    // MARK: - View Body

    var body: some View {
        ScrollView {
            mainContent
                .transition(.content)
        }
        .safeAreaInset(edge: .top, spacing: .zero) {
            header
        }
        .safeAreaInset(edge: .bottom) {
            if let button {
                button
                    .padding(.top, 24)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                    .background(ListFooterOverlayShadowView())
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollIndicators(.hidden)
        .animation(.contentFrameUpdate, value: state)
    }

    // MARK: - Sub Views

    private var header: some View {
        VStack(spacing: .zero) {
            headerContent
                .padding(.vertical, 4)
                .padding(.horizontal, 16)

            descriptionContent
        }
        .padding(.bottom, 16)
        .background(Colors.Background.tertiary.edgesIgnoringSafeArea(.all))
        .id(state)
        .transition(.opacity)
        .transformEffect(.identity)
        .animation(.headerOpacity.delay(0.3), value: state)
    }
}

private extension AnyTransition {
    static let content = AnyTransition.asymmetric(
        insertion: .opacity.animation(.curve(.easeInOutRefined, duration: 0.3).delay(0.2)),
        removal: .opacity.animation(.curve(.easeInOutRefined, duration: 0.3))
    )
}

private extension Animation {
    static let headerOpacity = Animation.curve(.easeOutStandard, duration: 0.3)
    static let contentFrameUpdate = Animation.curve(.easeInOutRefined, duration: 0.5)
}
