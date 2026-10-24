//
//  TopNavigationModifier.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccessibilityIdentifiers
import TangemAssets
import TangemFoundation
import TangemUIUtils

struct TopNavigationModifier<Slot: View>: ViewModifier {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.topNavigationDrawsBarBackground) private var drawsBarBackground

    private let contentPosition: TopNavigation.ContentPosition
    private let leadingPolicy: TopNavigation.LeadingPolicy
    private let actions: [TopNavigation.Action]
    private let actionsHaveBackground: Bool
    private let onClose: (() -> Void)?
    private let slot: Slot

    init(
        contentPosition: TopNavigation.ContentPosition,
        leading: TopNavigation.LeadingPolicy,
        actions: TopNavigation.Actions?,
        actionsHaveBackground: Bool,
        onClose: (() -> Void)?,
        @ViewBuilder slot: () -> Slot
    ) {
        self.contentPosition = contentPosition
        leadingPolicy = leading
        self.actions = actions?.values ?? []
        self.actionsHaveBackground = actionsHaveBackground
        self.onClose = onClose
        self.slot = slot()
    }

    private var resolvedLeading: TopNavigation.Action? {
        switch leadingPolicy {
        case .automatic: .back { dismiss() }
        case .custom(let action): action
        case .none, .image: nil
        }
    }

    private var barDynamicTypeSize: DynamicTypeSize {
        min(dynamicTypeSize, TopNavigationChromeMetrics.maxDynamicTypeSize)
    }

    @ViewBuilder
    func body(content: Content) -> some View {
        if drawsBarBackground {
            navigation(content)
                .translucentNavigationBar()
        } else {
            navigation(content)
                .clearNavigationBar()
        }
    }

    private func navigation(_ content: Content) -> some View {
        content
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar { toolbarContent }
            .toolbarRole(contentPosition == .start ? .editor : .automatic)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        leadingContent
        principalContent
        trailingContent
    }

    @ToolbarContentBuilder
    private var leadingContent: some ToolbarContent {
        if case .image(let image, let height) = leadingPolicy {
            leadingImageContent(image, height: height)
        } else if let leading = resolvedLeading {
            if #available(iOS 26.0, *) {
                ToolbarItem(placement: .topBarLeading) {
                    systemChrome([leading])
                }
                .prefersVerticalBar()
            } else {
                ToolbarItem(placement: .topBarLeading) {
                    chromeButton(leading)
                }
            }
        }
    }

    @ToolbarContentBuilder
    private func leadingImageContent(_ image: ImageType, height: CGFloat) -> some ToolbarContent {
        if #available(iOS 26.0, *) {
            ToolbarItem(placement: .topBarLeading) {
                leadingImage(image, height: height)
            }
            .sharedBackgroundVisibility(.hidden)
        } else {
            ToolbarItem(placement: .topBarLeading) {
                leadingImage(image, height: height)
            }
        }
    }

    private func leadingImage(_ image: ImageType, height: CGFloat) -> some View {
        image.image
            .renderingMode(.template)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: height)
            .fixedSize()
    }

    @ToolbarContentBuilder
    private var principalContent: some ToolbarContent {
        switch contentPosition {
        case .center:
            if #available(iOS 26.0, *) {
                ToolbarItem(placement: .principal) {
                    barTitle(.center)
                }
                .sharedBackgroundVisibility(.hidden)
            } else {
                ToolbarItem(placement: .principal) {
                    barTitle(.center)
                }
            }
        case .start:
            if #available(iOS 26.0, *) {
                ToolbarItem(placement: .principal) {
                    startPositionedTitle
                }
                .sharedBackgroundVisibility(.hidden)
            } else {
                ToolbarItem(placement: .principal) {
                    startPositionedTitle
                        .transaction { $0.disablesAnimations = true }
                }
            }
        }
    }

    private var startPositionedTitle: some View {
        barTitle(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ToolbarContentBuilder
    private var trailingContent: some ToolbarContent {
        if #available(iOS 26.0, *) {
            systemTrailingContent
        } else if actions.isNotEmpty || onClose != nil {
            ToolbarItem(placement: .topBarTrailing) {
                trailingGroup
            }
        }
    }

    @available(iOS 26.0, *)
    @ToolbarContentBuilder
    private var systemTrailingContent: some ToolbarContent {
        if actions.isNotEmpty {
            ToolbarItem(placement: .topBarTrailing) {
                systemChrome(actions)
            }
            .sharedBackgroundVisibility(actionsHaveBackground ? .automatic : .hidden)
            .prefersVerticalBar(!actions.contains(where: \.content.isTitle))
        }

        if let onClose {
            if actions.isNotEmpty {
                ToolbarSpacer(.fixed, placement: .topBarTrailing)
            }

            ToolbarItem(placement: .topBarTrailing) {
                systemChrome([closeAction(onClose)])
            }
            .prefersVerticalBar()
        }
    }

    private var trailingGroup: some View {
        barHosted {
            HStack(spacing: TopNavigationChromeMetrics.trailingGroupSpacing) {
                if actions.isNotEmpty {
                    TopNavigationActionsGroup(actions: actions, hasBackground: actionsHaveBackground)
                }

                if let onClose {
                    TopNavigationCircleButton(action: closeAction(onClose))
                }
            }
        }
    }

    private func closeAction(_ action: @escaping () -> Void) -> TopNavigation.Action {
        TopNavigation.Action.close(accessibilityIdentifier: CommonUIAccessibilityIdentifiers.closeButton, action: action)
    }

    private func barTitle(_ alignment: HorizontalAlignment) -> some View {
        barHosted {
            slot.environment(\.topNavigationContentAlignment, alignment)
        }
    }

    private func chromeButton(_ action: TopNavigation.Action) -> some View {
        barHosted {
            TopNavigationCircleButton(action: action)
        }
    }

    @available(iOS 26.0, *)
    private func systemChrome(_ actions: [TopNavigation.Action]) -> some View {
        barHosted {
            TopNavigationSystemChrome(actions: actions)
        }
    }

    /// The bar hosts its items outside the content's view tree and does not pass on every content-size-category
    /// change, so the ambient size — read here, in content scope — is injected explicitly, clamped to what the
    /// fixed-height bar can show.
    private func barHosted<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content().dynamicTypeSize(barDynamicTypeSize)
    }
}

private extension View {
    @ViewBuilder
    func clearNavigationBar() -> some View {
        if #available(iOS 26.0, *) {
            scrollEdgeEffectHidden(true, for: .top)
                .toolbarBackground(.hidden, for: .navigationBar)
        } else {
            toolbarBackground(.hidden, for: .navigationBar)
        }
    }
}

public extension EnvironmentValues {
    /// Cleared by a container that hosts the navigation stack on its own surface and fades its content itself.
    @Entry var topNavigationDrawsBarBackground = true
}
