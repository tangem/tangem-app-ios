//
//  AccountSelectorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils
import TangemLocalization
import TangemAccounts

struct AccountSelectorView: View {
    @ObservedObject var viewModel: AccountSelectorViewModel
    private let style: Style

    init(viewModel: AccountSelectorViewModel, style: Style = .legacy) {
        self.viewModel = viewModel
        self.style = style
    }

    var body: some View {
        switch style.kind {
        case .legacy:
            legacyBody
        case .addTokenRedesigned:
            redesignedBody
        }
    }
}

// MARK: - Legacy body

private extension AccountSelectorView {
    var legacyBody: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 0) {
                switch viewModel.displayMode {
                case .wallets:
                    legacyWalletsView
                case .accounts:
                    legacyAccountSectionsView
                }

                legacyLockedWalletsView
                    .padding(.top, 20)
            }
            .padding(style.contentInsets)
        }
    }

    var legacyWalletsView: some View {
        VStack(spacing: 6) {
            ForEach(viewModel.walletItems) { wallet in
                ZStack {
                    AccountSelectorWalletCellButtonView(
                        walletModel: wallet,
                        onTap: {
                            viewModel.handleViewAction(.selectItem(.wallet(wallet)))
                        }
                    )
                    legacySelectionBorder(for: .wallet(wallet))
                }
            }
        }
    }

    var legacyAccountSectionsView: some View {
        VStack(spacing: 0) {
            ForEach(viewModel.accountsSections) { section in
                VStack(spacing: 0) {
                    if viewModel.accountsSections.count > 1 {
                        legacySectionHeader(section.walletName)
                    }

                    VStack(spacing: 6) {
                        ForEach(section.accounts) { entry in
                            ZStack {
                                AccountRowButtonView(viewModel: entry.rowViewModel)
                                    .buttonStyle(.plain)
                                    .lineLimit(1)
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 14)
                                    .contentShape(.rect)
                                    .background(Colors.Background.action)
                                    .cornerRadius(14, corners: .allCorners)

                                legacySelectionBorder(for: .account(entry.item))
                            }
                        }
                    }
                }
                .padding(.bottom, 24)
            }
        }
    }

    @ViewBuilder
    var legacyLockedWalletsView: some View {
        if viewModel.lockedWalletItems.isNotEmpty {
            VStack(spacing: 6) {
                legacySectionHeader(Localization.commonLockedWallets)

                ForEach(viewModel.lockedWalletItems) {
                    AccountSelectorWalletCellButtonView(
                        walletModel: $0,
                        onTap: {}
                    )
                }
            }
        }
    }

    func legacySectionHeader(_ title: String) -> some View {
        Text(title)
            .frame(maxWidth: .infinity, alignment: .leading)
            .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
            .padding(.horizontal, 12)
            .padding(.bottom, 10)
    }

    @ViewBuilder
    func legacySelectionBorder(for cell: AccountSelectorCellModel) -> some View {
        if viewModel.isCellSelected(for: cell) {
            RoundedRectangle(cornerRadius: 14)
                .stroke(Colors.Text.accent, lineWidth: 1)
        }
    }
}

// MARK: - Redesigned body

private extension AccountSelectorView {
    var redesignedBody: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: Redesigned.sectionSpacing) {
                redesignedContentCard

                if viewModel.lockedWalletItems.isNotEmpty {
                    redesignedLockedCard
                }
            }
            .padding(.horizontal, Redesigned.horizontalPadding)
            .padding(.vertical, Redesigned.scrollVerticalPadding)
        }
    }

    @ViewBuilder
    var redesignedContentCard: some View {
        VStack(spacing: 0) {
            switch viewModel.displayMode {
            case .wallets:
                ForEach(viewModel.walletItems) { wallet in
                    AccountSelectorWalletCellButtonView(walletModel: wallet) {
                        viewModel.handleViewAction(.selectItem(.wallet(wallet)))
                    }
                }

            case .accounts:
                let showSectionHeaders = viewModel.accountsSections.count > 1
                ForEach(viewModel.accountsSections) { section in
                    if showSectionHeaders {
                        redesignedWalletSectionHeader(
                            name: section.walletName,
                            thumbnail: section.walletThumbnailType
                        )
                    }

                    ForEach(section.accounts) { entry in
                        AccountRowButtonView(viewModel: entry.rowViewModel)
                            .buttonStyle(.plain)
                            .padding(Redesigned.cellPadding)
                    }
                }
            }
        }
        .background(Color.Tangem.Surface.level3)
        .cornerRadiusContinuous(Redesigned.cornerRadius)
    }

    var redesignedLockedCard: some View {
        VStack(spacing: 0) {
            redesignedSectionHeader(Localization.commonLockedWallets)

            ForEach(viewModel.lockedWalletItems) { wallet in
                AccountSelectorWalletCellButtonView(walletModel: wallet) {}
                    .disabled(true)
            }
        }
        .background(Color.Tangem.Surface.level3)
        .cornerRadiusContinuous(Redesigned.cornerRadius)
    }

    func redesignedSectionHeader(_ title: String) -> some View {
        Text(title)
            .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Redesigned.sectionHeaderHorizontalPadding)
            .padding(.top, Redesigned.sectionHeaderTopPadding)
            .padding(.bottom, Redesigned.sectionHeaderBottomPadding)
    }

    func redesignedWalletSectionHeader(name: String, thumbnail: ThumbnailWalletViewType?) -> some View {
        HStack(spacing: Redesigned.walletHeaderSpacing) {
            Text(name)
                .style(.Tangem.Subheadline.medium, color: .Tangem.Graphic.Neutral.tertiary)

            thumbnail.map { type in
                Color.Tangem.Graphic.Neutral.tertiaryConstant
                    .frame(width: Redesigned.walletThumbnailWidth)
                    .mask {
                        MiniatureWalletView(type: type)
                    }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Redesigned.sectionHeaderHorizontalPadding)
        .padding(.top, Redesigned.sectionHeaderTopPadding)
        .padding(.bottom, Redesigned.sectionHeaderBottomPadding)
    }

    enum Redesigned {
        static let horizontalPadding: CGFloat = 16
        static let scrollVerticalPadding: CGFloat = 16
        static let sectionSpacing: CGFloat = 16
        static let cornerRadius: CGFloat = 20
        static let cellPadding: CGFloat = 14
        static let sectionHeaderHorizontalPadding: CGFloat = 16
        static let sectionHeaderTopPadding: CGFloat = 14
        static let sectionHeaderBottomPadding: CGFloat = 4
        static let walletHeaderSpacing: CGFloat = 4
        static let walletThumbnailWidth: CGFloat = 20
    }
}

// MARK: - Style

extension AccountSelectorView {
    struct Style {
        let contentInsets: EdgeInsets
        fileprivate let kind: Kind

        fileprivate enum Kind {
            case legacy
            case addTokenRedesigned
        }

        static let legacy = Style(
            contentInsets: EdgeInsets(top: 12, leading: 16, bottom: 16, trailing: 16),
            kind: .legacy
        )

        static let addAndManage = Style(
            contentInsets: EdgeInsets(top: 12, leading: 16, bottom: 0, trailing: 16),
            kind: .legacy
        )

        static let addTokenRedesigned = Style(
            contentInsets: .init(),
            kind: .addTokenRedesigned
        )
    }
}
