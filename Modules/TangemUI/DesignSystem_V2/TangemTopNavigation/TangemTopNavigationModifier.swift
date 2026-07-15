//
//  TangemTopNavigationModifier.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemFoundation
import TangemUIUtils

struct TangemTopNavigationModifier<Slot: View>: ViewModifier {
    private let contentPosition: TangemTopNavigation.ContentPosition
    private let leading: TangemTopNavigation.Action?
    private let actions: [TangemTopNavigation.Action]
    private let onClose: (() -> Void)?
    private let slot: Slot

    init(
        contentPosition: TangemTopNavigation.ContentPosition,
        leading: TangemTopNavigation.Action?,
        actions: [TangemTopNavigation.Action],
        onClose: (() -> Void)?,
        @ViewBuilder slot: () -> Slot
    ) {
        let maxActionCount = TangemTopNavigationConstants.maxActionCount
        assert(actions.count <= maxActionCount, "TangemTopNavigation supports at most \(maxActionCount) actions")
        self.contentPosition = contentPosition
        self.leading = leading
        self.actions = Array(actions.prefix(maxActionCount))
        self.onClose = onClose
        self.slot = slot()
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
        if let leading {
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
                        TangemTopNavigationNativeBarButton(action: actions[index])
                    }
                }
            } else {
                ToolbarItem(placement: .topBarTrailing) {
                    TangemTopNavigationActionsPill(actions: actions)
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
                chromeButton(TangemTopNavigation.Action.close(action: onClose))
            }
        }
    }

    private func barTitle(_ alignment: HorizontalAlignment) -> some View {
        slot.environment(\.tangemTopNavigationContentAlignment, alignment)
    }

    @ViewBuilder
    private func chromeButton(_ action: TangemTopNavigation.Action) -> some View {
        if #available(iOS 26.0, *) {
            TangemTopNavigationNativeBarButton(action: action)
        } else {
            TangemTopNavigationCircleButton(action: action)
        }
    }
}
