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
import TangemUIUtils

struct TopNavigationModifier<Slot: View>: ViewModifier {
    @Environment(\.dismiss) private var dismiss

    private let contentPosition: TopNavigation.ContentPosition
    private let leadingPolicy: TopNavigation.LeadingPolicy
    private let actions: [TopNavigation.Action]
    private let onClose: (() -> Void)?
    private let slot: Slot

    init(
        contentPosition: TopNavigation.ContentPosition,
        leading: TopNavigation.LeadingPolicy,
        actions: TopNavigation.Actions?,
        onClose: (() -> Void)?,
        @ViewBuilder slot: () -> Slot
    ) {
        self.contentPosition = contentPosition
        leadingPolicy = leading
        self.actions = actions?.values ?? []
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

        switch contentPosition {
        case .center:
            ToolbarItem(placement: .principal) {
                barTitle(.center)
            }
        case .start:
            if #available(iOS 26.0, *) {
                ToolbarItem(placement: .principal) {
                    barTitle(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .sharedBackgroundVisibility(.hidden)
            } else {
                ToolbarItem(placement: .principal) {
                    barTitle(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .transaction { $0.disablesAnimations = true }
                }
            }
        }

        if actions.isNotEmpty {
            if #available(iOS 26.0, *) {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    ForEach(actions.indices, id: \.self) { index in
                        TopNavigationNativeBarButton(action: actions[index])
                    }
                }
            } else {
                ToolbarItem(placement: .topBarTrailing) {
                    TopNavigationActionsPill(actions: actions)
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
        slot.environment(\.topNavigationContentAlignment, alignment)
    }

    @ViewBuilder
    private func chromeButton(_ action: TopNavigation.Action) -> some View {
        if #available(iOS 26.0, *) {
            TopNavigationNativeBarButton(action: action)
        } else {
            TopNavigationCircleButton(action: action)
        }
    }
}
