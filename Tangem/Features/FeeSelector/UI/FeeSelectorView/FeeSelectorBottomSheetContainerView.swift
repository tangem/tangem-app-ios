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
        contentView
            .animation(.contentFrameUpdate, value: state)
            .floatingSheetConfiguration { configuration in
                configuration.sheetBackgroundColor = Colors.Background.tertiary
                configuration.sheetFrameUpdateAnimation = .contentFrameUpdate
                configuration.backgroundInteractionBehavior = .consumeTouches
            }
    }

    private var contentView: some View {
        ScrollView {
            mainContentView
                .padding(.bottom, button == nil ? .zero : Constants.mainContentViewBottomPadding)
        }
        .safeAreaInset(edge: .bottom, spacing: .zero) {
            buttonView
                .padding(.horizontal, Constants.standardSpacing)
                .padding(.bottom, Constants.standardSpacing)
        }
        .safeAreaInset(edge: .top, spacing: .zero) {
            header
                .padding(.bottom, Constants.headerVerticalSpacing)
                .padding(.horizontal, Constants.standardSpacing)
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollIndicators(.hidden)
    }

    // MARK: - Sub Views

    private var buttonView: some View {
        button
            .background(ListFooterOverlayShadowView())
            .transition(.footer)
            .animation(.contentFrameUpdate, value: state)
    }

    private var mainContentView: some View {
        VStack(spacing: Constants.standardSpacing) {
            descriptionContent
            mainContent
        }
        .transition(.content)
    }

    private var header: some View {
        VStack(spacing: .zero) {
            headerContent
        }
        .transition(.content)
        .id(state)
        .transition(.opacity)
        .transformEffect(.identity)
        .animation(.headerOpacity.delay(0.2), value: state)
        .background(Colors.Background.tertiary.edgesIgnoringSafeArea(.all))
    }
}

// MARK: - Animations and Transitions

private extension AnyTransition {
    static let content = AnyTransition.asymmetric(
        insertion: .opacity.animation(.curve(.easeInOutRefined, duration: 0.3).delay(0.2)),
        removal: .opacity.animation(.curve(.easeInOutRefined, duration: 0.1))
    )

    static let footer = AnyTransition.asymmetric(
        insertion: .offset(y: 200).combined(with: .opacity.animation(.footerOpacity.delay(0.2))),
        removal: .offset(y: 200).combined(with: .opacity.animation(.footerOpacity))
    )
}

private extension Animation {
    static let headerOpacity = Animation.curve(.easeOutStandard, duration: 0.2)
    static let contentFrameUpdate = Animation.curve(.easeInOutRefined, duration: 0.5)
    static let footerOpacity = Animation.curve(.easeOutEmphasized, duration: 0.3)
}

// MARK: - Constants

private enum Constants {
    static let standardSpacing: CGFloat = 16
    static let headerVerticalSpacing: CGFloat = 4
    static let mainContentViewBottomPadding: CGFloat = 24
}
