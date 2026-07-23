//
//  AddFundsView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

struct AddFundsView: View {
    @ObservedObject var viewModel: AddFundsViewModel

    var body: some View {
        redesignBody
    }

    // MARK: - Redesign

    @ViewBuilder
    private var redesignBody: some View {
        switch viewModel.mode {
        case .sheet(.compact):
            compactSheetContent
                .applyFloatingSheetStyling()

        case .sheet(.full):
            fullSheetContent
                .applyFloatingSheetStyling()

        case .stack:
            stackContent
        }
    }

    // MARK: - Sheet — compact

    private var compactSheetContent: some View {
        VStack(spacing: 16) {
            sheetHeader

            optionsSection

            primaryButton
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
    }

    private var sheetHeader: some View {
        BottomSheetHeaderView(
            title: viewModel.title,
            leading: {
                if viewModel.showsBackButton {
                    NavigationBarButton.back(action: viewModel.userDidTapBack)
                }
            },
            trailing: {
                NavigationBarButton.close(action: viewModel.close)
            }
        )
    }

    // MARK: - Sheet — full

    private var fullSheetContent: some View {
        VStack(spacing: 16) {
            sheetHeader

            AddFundsTokenInfoView(viewData: viewModel.tokenInfoViewData)

            optionsSection

            primaryButton
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
    }

    // MARK: - Stack

    private var stackContent: some View {
        VStack(spacing: 16) {
            AddFundsStackNavigationBar(
                title: viewModel.title,
                onBack: viewModel.showsBackButton ? viewModel.userDidTapBack : nil,
                onClose: viewModel.close
            )

            AddFundsTokenInfoView(viewData: viewModel.tokenInfoViewData)
                .padding(.top, 64)

            Spacer()

            optionsSection

            primaryButton
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
        .background(Color.Tangem.Surface.level2.ignoresSafeArea())
        .navigationBarHidden(true)
    }

    // MARK: - Shared

    private var optionsSection: some View {
        VStack(spacing: .unit(.x2)) {
            ForEach(viewModel.options) { option in
                AddFundsOptionView(option: option, isEnabled: viewModel.isEnabled(option), action: {
                    viewModel.userDidTap(option)
                })
            }
        }
    }

    @ViewBuilder
    private var primaryButton: some View {
        switch viewModel.primaryAction {
        case .close(let title):
            tangemButton(title: title)
        case .goToToken:
            tangemButton(title: Localization.commonGoToToken)
        case .hidden:
            EmptyView()
        }
    }

    private func tangemButton(title: String) -> some View {
        TangemButton(
            content: .text(AttributedString(title)),
            action: viewModel.userDidTapPrimary
        )
        .setStyleType(.secondary)
        .setHorizontalLayout(.infinity)
        .setSize(.x12)
    }
}

private extension View {
    func applyFloatingSheetStyling() -> some View {
        floatingSheetConfiguration { configuration in
            configuration.sheetBackgroundColor = Color.Tangem.Surface.level2
            configuration.backgroundInteractionBehavior = .tapToDismiss
        }
    }
}
