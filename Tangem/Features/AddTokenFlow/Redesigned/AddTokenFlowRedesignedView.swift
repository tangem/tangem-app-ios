//
//  AddTokenFlowRedesignedView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemLocalization

struct AddTokenFlowRedesignedView: View {
    @ObservedObject var viewModel: AddTokenFlowRedesignedViewModel

    @State private var hasAppeared = false

    var body: some View {
        contentView
            .animation(hasAppeared ? .contentFrameUpdate : nil, value: viewModel.viewState)
            .onAppear { hasAppeared = true }
            .floatingSheetConfiguration { configuration in
                configuration.sheetFrameUpdateAnimation = .contentFrameUpdate
                configuration.backgroundInteractionBehavior = .consumeTouches
                configuration.sheetBackgroundColor = Color.Tangem.Surface.level2
            }
    }

    private var contentView: some View {
        ZStack {
            switch viewModel.viewState {
            case .confirm(let confirmViewModel):
                AddTokenConfirmView(viewModel: confirmViewModel)
                    .animation(.contentFrameUpdate, value: confirmViewModel.isSaving)
                    .animation(.contentFrameUpdate, value: confirmViewModel.isTokenAlreadyAdded)
                    .transition(.content)

            case .networkPicker(let pickerViewModel):
                AddTokenNetworkPickerView(viewModel: pickerViewModel)
                    .transition(.content)

            case .accountPicker(let pickerViewModel):
                AccountSelectorView(viewModel: pickerViewModel, style: .addTokenRedesigned)
                    .overlay(alignment: .bottom) { bottomFadeOverlay }
                    .safeAreaInset(edge: .bottom, spacing: 0) {
                        AccountPickerCancelButton(onCancel: viewModel.back)
                            .background(Color.Tangem.Surface.level3)
                    }
                    .transition(.content)
            }
        }
        .safeAreaInset(edge: .top, spacing: .zero) {
            header
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    private var bottomFadeOverlay: some View {
        LinearGradient(
            colors: [
                Color.Tangem.Surface.level3.opacity(0),
                Color.Tangem.Surface.level3,
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: 80)
        .allowsHitTesting(false)
    }

    private var header: some View {
        ZStack(alignment: .top) {
            LinearGradient(
                colors: [
                    Color.Tangem.Surface.level2,
                    Color.Tangem.Surface.level2.opacity(0),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 80)
            .allowsHitTesting(false)

            let backButtonAction = viewModel.viewState.canGoBack
                ? { viewModel.back() }
                : nil
            let closeButtonAction = viewModel.viewState.canBeClosed
                ? { viewModel.close() }
                : nil

            FloatingSheetNavigationBarView(
                title: viewModel.viewState.title,
                backgroundColor: .clear,
                backButtonAction: backButtonAction,
                closeButtonAction: closeButtonAction
            )
            .id(viewModel.viewState.id)
            .transition(.opacity)
            .transformEffect(.identity)
            .animation(hasAppeared ? .headerOpacity.delay(0.2) : nil, value: viewModel.viewState)
        }
    }
}

// MARK: - Animations

private extension Animation {
    static let headerOpacity = Animation.curve(.easeOutStandard, duration: 0.2)
    static let contentFrameUpdate = Animation.curve(.easeInOutRefined, duration: 0.5)
}

private extension AnyTransition {
    static let content = AnyTransition.asymmetric(
        insertion: .opacity.animation(.curve(.easeInOutRefined, duration: 0.3).delay(0.2)),
        removal: .opacity.animation(.curve(.easeInOutRefined, duration: 0.3))
    )
}

// MARK: - Cancel button

private struct AccountPickerCancelButton: View {
    let onCancel: () -> Void

    var body: some View {
        TangemButton(
            content: .text(AttributedString(Localization.commonCancel)),
            action: onCancel
        )
        .setStyleType(.secondary)
        .setSize(.x12)
        .setHorizontalLayout(.infinity)
        .padding(.horizontal, AddTokenRedesignedConstants.horizontalPadding)
        .padding(.bottom, AddTokenRedesignedConstants.accountPickerScrollVerticalPadding)
    }
}
