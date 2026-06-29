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
        if viewModel.isRedesign {
            redesignBody
        } else {
            legacyBody
        }
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
            BottomSheetHeaderView(title: viewModel.title, trailing: {
                NavigationBarButton.close(action: viewModel.close)
            })

            optionsSection

            primaryButton
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
    }

    // MARK: - Sheet — full

    private var fullSheetContent: some View {
        VStack(spacing: 16) {
            BottomSheetHeaderView(title: viewModel.title, trailing: {
                NavigationBarButton.close(action: viewModel.close)
            })

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
                accountBadge: viewModel.accountBadge,
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
                AddFundsOptionView(option: option, action: {
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

    // MARK: - Legacy

    private var legacyBody: some View {
        VStack(spacing: 0) {
            legacyHeader
                .padding(.top, 64)

            Spacer()

            VStack(spacing: 8) {
                legacyActionRow(
                    icon: Assets.Glyphs.walletNew,
                    title: Localization.commonBuy,
                    subtitle: Localization.addfundsBuyRowDescription,
                    action: { viewModel.userDidTap(.buy) }
                )
                .defaultRoundedBackground(with: Colors.Background.action, verticalPadding: 0, horizontalPadding: 0)

                legacyActionRow(
                    icon: Assets.exchangeMini,
                    title: Localization.commonSwap,
                    subtitle: Localization.addfundsSwapRowDescription,
                    action: { viewModel.userDidTap(.swap) }
                )
                .defaultRoundedBackground(with: Colors.Background.action, verticalPadding: 0, horizontalPadding: 0)

                legacyActionRow(
                    icon: Assets.qrCode,
                    title: Localization.commonReceive,
                    subtitle: Localization.addfundsReceiveRowDescription,
                    action: { viewModel.userDidTap(.receive) }
                )
                .defaultRoundedBackground(with: Colors.Background.action, verticalPadding: 0, horizontalPadding: 0)
            }
            .padding(.bottom, 24)

            MainButton(settings: .init(
                title: Localization.commonGoToToken,
                style: .secondary,
                size: .default,
                action: viewModel.userDidTapGoToToken
            ))
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .padding(.top, 12)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Colors.Background.tertiary.ignoresSafeArea())
        .navigationTitle(Localization.commonAddToken)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            NavigationToolbarButton.close(placement: .topBarTrailing, action: viewModel.close)
        }
    }

    private var legacyHeader: some View {
        VStack(spacing: 20) {
            TokenIcon(
                tokenIconInfo: viewModel.tokenIconInfo,
                size: .init(bothDimensions: 96)
            )

            VStack(spacing: 4) {
                Text(viewModel.fiatBalanceText)
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(Colors.Text.primary1)

                Text(viewModel.cryptoBalanceText)
                    .style(Fonts.Regular.body, color: Colors.Text.tertiary)
            }
        }
    }

    private func legacyActionRow(icon: ImageType, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                GetTokenActionRowView(icon: icon, title: title, subtitle: subtitle)

                Assets.chevron.image
                    .renderingMode(.template)
                    .foregroundStyle(Colors.Icon.informative)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 18)
        }
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
