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

struct FeeSelectorBottomSheetContainerView<HeaderContent: View, DescriptionContent: View, MainContent: View, ButtonContent: View>: View {
    // MARK: - UI

    private let state: AnyHashable
    private let headerContent: HeaderContent
    private let descriptionContent: DescriptionContent
    private let mainContent: MainContent
    private let buttonContent: ButtonContent
    private let showsButton: Bool
    private let verticalSwipeBehavior: FloatingSheetConfiguration.VerticalSwipeBehavior?

    // MARK: - Init

    init(
        state: AnyHashable,
        showsButton: Bool = true,
        verticalSwipeBehavior: FloatingSheetConfiguration.VerticalSwipeBehavior? = nil,
        @ViewBuilder button: () -> ButtonContent,
        @ViewBuilder headerContent: () -> HeaderContent = { EmptyView() },
        @ViewBuilder descriptionContent: () -> DescriptionContent = { EmptyView() },
        @ViewBuilder mainContent: () -> MainContent = { EmptyView() }
    ) {
        self.state = state
        self.showsButton = showsButton
        self.verticalSwipeBehavior = verticalSwipeBehavior
        buttonContent = button()
        self.headerContent = headerContent()
        self.descriptionContent = descriptionContent()
        self.mainContent = mainContent()
    }

    // MARK: - View Body

    var body: some View {
        contentView
            .animation(.contentFrameUpdate, value: state)
            .floatingSheetConfiguration { configuration in
                configuration.sheetBackgroundColor = Colors.Background.tertiary
                configuration.sheetFrameUpdateAnimation = .contentFrameUpdate
                configuration.backgroundInteractionBehavior = .tapToDismiss
                configuration.verticalSwipeBehavior = verticalSwipeBehavior
            }
    }

    private var contentView: some View {
        ScrollView {
            mainContentView
                .padding(.top, Constants.standardSpacing)
                .padding(.bottom, showsButton ? Constants.mainContentViewBottomPadding : .zero)
        }
        .safeAreaInset(edge: .bottom, spacing: .zero) {
            buttonView
                .padding(.horizontal, Constants.standardSpacing)
                .padding(.bottom, Constants.standardSpacing)
        }
        .safeAreaInset(edge: .top, spacing: .zero) {
            header
                .padding(.top, Constants.headerVerticalSpacing)
                .padding(.horizontal, Constants.standardSpacing)
                .background(Colors.Background.tertiary.edgesIgnoringSafeArea(.all))
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollIndicators(.hidden)
    }

    // MARK: - Sub Views

    private var buttonView: some View {
        buttonContent
            .background(ListFooterOverlayShadowView())
            .transition(.footer)
            .animation(.contentFrameUpdate, value: state)
    }

    private var mainContentView: some View {
        VStack(spacing: Constants.standardSpacing) {
            mainContent
        }
        .transition(.content)
    }

    private var header: some View {
        VStack(spacing: .zero) {
            headerContent
            descriptionContent
        }
        .transition(.content)
        .id(state)
        .transition(.opacity)
        .transformEffect(.identity)
        .animation(.headerOpacity.delay(0.2), value: state)
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
