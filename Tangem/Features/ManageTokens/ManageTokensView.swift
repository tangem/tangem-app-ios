//
//  ManageTokensView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccessibilityIdentifiers
import TangemLocalization
import TangemAssets
import TangemUIUtils
import TangemUI

struct ManageTokensView: View {
    @ObservedObject var viewModel: ManageTokensViewModel
    @State private var contentOffset: CGPoint = .zero
    private let style: Style

    init(viewModel: ManageTokensViewModel, style: Style = .legacy) {
        self.viewModel = viewModel
        self.style = style
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                CustomSearchBar(
                    searchText: $viewModel.searchText,
                    placeholder: Localization.commonSearch,
                    style: style.searchBarStyle,
                    cancelButtonAction: nil
                )
                .padding(.horizontal, style.searchBarHorizontalPadding)
                .padding(.vertical, 12)

                if style.showsScrollDivider, contentOffset.y > 0 {
                    Divider()
                }

                if style.addCustomTokenPlacement == .inlineRow, viewModel.canAddCustomToken {
                    addCustomTokenRow.padding(.bottom, 14)
                }

                ManageTokensListView(viewModel: viewModel.manageTokensListViewModel, header: customTokensList)
                    .addContentOffsetObserver($contentOffset)
                    .backgroundColor(style.listBackgroundColor)
                    .roundedCorners(style.listHasRoundedCorners)
            }
            .padding(.horizontal, style.outerHorizontalPadding)

            VStack {
                Spacer()

                MainButton(
                    title: Localization.commonSave,
                    icon: savingIcon,
                    isLoading: viewModel.isSavingChanges,
                    accessibilityIdentifier: ManageTokensAccessibilityIdentifiers.saveButton,
                    action: viewModel.saveChanges
                )
                .padding(.bottom, 10)
                .padding(.horizontal, 16)
                .background(
                    ListFooterOverlayShadowView()
                        .padding(.top, -30)
                )
                .hidden(viewModel.isPendingListEmpty)
                .animation(.default, value: viewModel.isPendingListEmpty)
            }
        }
        .background(style.viewBackgroundColor.ignoresSafeArea())
        .navigationTitle(Text(Localization.addTokensTitle))
        .scrollDismissesKeyboard(.immediately)
        .keyboardType(.alphabet)
        .bindAlert($viewModel.alert)
        .if(style.addCustomTokenPlacement == .toolbar && viewModel.canAddCustomToken) {
            $0.toolbar {
                NavigationToolbarButton.add(
                    placement: .topBarTrailing,
                    action: viewModel.openAddCustomToken
                )
            }
        }
    }

    private var savingIcon: MainButton.Icon? {
        viewModel.needsCardDerivation ? .trailing(Assets.tangemIcon) : nil
    }

    private var addCustomTokenRow: some View {
        Button(action: viewModel.openAddCustomToken) {
            HStack(spacing: 12) {
                ZStack(alignment: .center) {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Colors.Icon.accent.opacity(0.1))
                        .frame(width: 36, height: 36)

                    Assets.plus24.image
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                        .foregroundStyle(Colors.Icon.accent)
                }

                Text(Localization.addCustomTokenTitle)
                    .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

                Spacer(minLength: 0)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Colors.Background.action)
            )
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    private func customTokensList() -> some View {
        LazyVStack(spacing: 0) {
            ForEach(viewModel.customTokensList) { item in
                CustomTokenItemView(
                    info: item,
                    removeAction: { info in
                        viewModel.removeCustomToken(info)
                    }
                )
            }
        }
    }
}

// MARK: - Style

extension ManageTokensView {
    struct Style {
        let searchBarStyle: CustomSearchBar.Style
        let searchBarHorizontalPadding: CGFloat
        let showsScrollDivider: Bool
        let addCustomTokenPlacement: AddCustomTokenPlacement
        let listBackgroundColor: Color
        let listHasRoundedCorners: Bool
        let outerHorizontalPadding: CGFloat
        let viewBackgroundColor: Color

        static let legacy = Style(
            searchBarStyle: .default,
            searchBarHorizontalPadding: 16,
            showsScrollDivider: true,
            addCustomTokenPlacement: .toolbar,
            listBackgroundColor: .clear,
            listHasRoundedCorners: false,
            outerHorizontalPadding: 0,
            viewBackgroundColor: Colors.Background.primary
        )

        static let addAndManage = Style(
            searchBarStyle: .focused,
            searchBarHorizontalPadding: 0,
            showsScrollDivider: false,
            addCustomTokenPlacement: .inlineRow,
            listBackgroundColor: Colors.Background.action,
            listHasRoundedCorners: true,
            outerHorizontalPadding: 16,
            viewBackgroundColor: Colors.Background.tertiary
        )

        enum AddCustomTokenPlacement {
            case toolbar
            case inlineRow
        }
    }
}

#Preview {
    let fakeModel = FakeUserWalletModel.wallet3Cards
    let accountModelsManager = AccountModelsManagerMock()
    let context = CommonManageTokensContext(
        accountModelsManager: accountModelsManager,
        currentAccount: accountModelsManager.cryptoAccountModels[0]
    )

    let adapter = ManageTokensAdapter(
        settings: .init(
            existingCurves: fakeModel.config.existingCurves,
            supportedBlockchains: fakeModel.config.supportedBlockchains,
            hardwareLimitationUtil: HardwareLimitationsUtil(config: fakeModel.config),
            analyticsSourceRawValue: "preview",
            context: context
        )
    )

    NavigationStack {
        ManageTokensView(viewModel: .init(
            adapter: adapter,
            context: context,
            coordinator: nil
        ))
    }
}
