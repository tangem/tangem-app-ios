//
//  TopNavigationModifier.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemFoundation

struct TopNavigationModifier<Slot: View>: ViewModifier {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

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
        case .none: nil
        }
    }

    private var barDynamicTypeSize: DynamicTypeSize {
        min(dynamicTypeSize, TopNavigationChromeMetrics.maxDynamicTypeSize)
    }

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            navigation(content)
        } else {
            navigation(content)
                .backportTranslucentNavigationBar()
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
        if let leading = resolvedLeading {
            ToolbarItem(placement: .topBarLeading) {
                chromeButton(leading)
            }
        }

        principalContent
        trailingContent
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
        if actions.isNotEmpty {
            if #available(iOS 26.0, *) {
                ToolbarItem(placement: .topBarTrailing) {
                    barHosted {
                        TopNavigationNativeActionsGroup(actions: actions, hasBackground: actionsHaveBackground)
                    }
                }
                .sharedBackgroundVisibility(.hidden)
            } else {
                ToolbarItem(placement: .topBarTrailing) {
                    barHosted {
                        TopNavigationActionsPill(actions: actions, hasBackground: actionsHaveBackground)
                    }
                }
            }
        }

        if onClose != nil, actions.isNotEmpty {
            if #available(iOS 26.0, *) {
                ToolbarSpacer(.fixed, placement: .topBarTrailing)
            }
        }

        if let onClose {
            ToolbarItem(placement: .topBarTrailing) {
                chromeButton(TopNavigation.Action.close(action: onClose))
            }
        }
    }

    private func barTitle(_ alignment: HorizontalAlignment) -> some View {
        barHosted {
            slot.environment(\.topNavigationContentAlignment, alignment)
        }
    }

    private func chromeButton(_ action: TopNavigation.Action) -> some View {
        barHosted {
            if #available(iOS 26.0, *) {
                TopNavigationNativeBarButton(action: action)
            } else {
                TopNavigationCircleButton(action: action)
            }
        }
    }

    /// The bar hosts its items outside the content's view tree and does not pass on every content-size-category
    /// change, so the ambient size — read here, in content scope — is injected explicitly, clamped to what the
    /// fixed-height bar can show.
    private func barHosted<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content().dynamicTypeSize(barDynamicTypeSize)
    }
}
