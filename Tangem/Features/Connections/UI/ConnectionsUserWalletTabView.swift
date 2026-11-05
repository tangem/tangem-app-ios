//
//  ConnectionsUserWalletTabView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import Kingfisher
import TangemAccounts
import TangemAssets
import TangemMCP
import TangemUI

struct ConnectionsUserWalletTabView: View {
    @ObservedObject var viewModel: ConnectionsViewModel
    let tabID: ConnectionsViewState.UserWalletTab.ID
    let imageCache: Kingfisher.ImageCache

    private var tab: ConnectionsViewState.UserWalletTab {
        guard let tab = viewModel.state.tabs.first(where: { $0.id == tabID }) else {
            preconditionFailure("tabID must match one of the tabs. Developer mistake.")
        }

        return tab
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 24) {
                    stateView(proxy)
                }
                .padding(.horizontal, 16)
            }
        }
    }

    @ViewBuilder
    private func stateView(_ geometryProxy: GeometryProxy) -> some View {
        if let emptyStateSection = tab.emptyStateSection {
            emptyState(emptyStateSection)
                .frame(height: geometryProxy.size.height - geometryProxy.safeAreaInsets.top)
                .transition(.opacity)

        } else {
            mcpSessionsSection(tab.mcpSessionsSection)
            dAppsSectionView(tab.dAppsSection)
        }
    }

    private func emptyState(_ section: ConnectionsViewState.UserWalletTab.EmptyStateSection) -> some View {
        VStack(spacing: 16) {
            Avatar(.icon(DesignSystem.Icons.GridPlus.regular28, appearance: .info), size: .size72)

            VStack(spacing: 8) {
                Text(section.title)
                    .font(token: DesignSystem.Font.headingSmallToken)
                    .foregroundStyle(DesignSystem.Color.textPrimary)

                Text(section.subtitle)
                    .font(token: DesignSystem.Font.subheadingMediumToken)
                    .foregroundStyle(DesignSystem.Color.textSecondary)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - MCP sessions

    @ViewBuilder
    private func mcpSessionsSection(_ section: ConnectionsViewState.UserWalletTab.MCPSessionsSection) -> some View {
        if !section.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                sectionTitle(section.title)

                switch section.state {
                case .loading:
                    loadingStubsSectionView(stubsCount: 3)
                        .transition(.opacity)

                case .failed(let failedState):
                    mcpFailedStateView(failedState)
                        .transition(.opacity)

                case .content(let sessionRows):
                    ForEach(sessionRows) { sessionRow in
                        mcpSessionRow(sessionRow)
                    }
                    .transition(.opacity)

                    if section.isAwaitingNewSession {
                        loadingShimmerStub
                            .background(DesignSystem.Color.bgSecondary, in: .rect(cornerRadius: 24))
                            .transition(.opacity)
                    }
                }
            }
        }
    }

    private func mcpFailedStateView(_ failedState: ConnectionsViewState.UserWalletTab.MCPSessionsSection.FailedState) -> some View {
        Row(title: failedState.title, subtitle: failedState.subtitle)
            .lineOrder(.secondaryFirst)
            .start {
                Avatar(.icon(DesignSystem.Icons.Error.regular20, appearance: .error))
            }
            .end {
                TangemUI.Button(icon: DesignSystem.Icons.ArrowRefresh.regular20, accessibilityLabel: failedState.subtitle) {
                    viewModel.handle(action: .mcpSessionsReloadButtonTapped)
                }
                .styleType(.secondary(.default))
                .size(.x8)
                .loading(.spinner(if: failedState.isReloading))
            }
            .onTap { viewModel.handle(action: .mcpSessionsReloadButtonTapped) }
            .background(DesignSystem.Color.bgSecondary, in: .rect(cornerRadius: 24))
    }

    private func mcpSessionRow(_ sessionRow: ConnectionsViewState.UserWalletTab.MCPSessionsSection.SessionRow) -> some View {
        Row(title: sessionRow.agentName, subtitle: sessionRow.agentHost)
            .start { remoteIconView(sessionRow.session.agent.icon, fallbackIcon: DesignSystem.Icons.Server.filled20) }
            .onTap { viewModel.handle(action: .mcpSessionTapped(sessionRow.session)) }
            .background(DesignSystem.Color.bgSecondary, in: .rect(cornerRadius: 24))
    }

    // MARK: - Wallet Connect

    @ViewBuilder
    private func dAppsSectionView(_ dAppsSection: ConnectionsViewState.UserWalletTab.WalletConnectDAppsSection?) -> some View {
        if let dAppsSection, !dAppsSection.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                sectionTitle(dAppsSection.title)

                switch dAppsSection.state {
                case .loading:
                    loadingStubsSectionView(stubsCount: 5)

                case .content(.flat(let dApps)):
                    dAppsWithoutAccountGrouping(dApps)

                case .content(.byAccount(let accountSections)):
                    ForEach(accountSections) { accountSection in
                        accountSectionView(accountSection)
                    }
                }
            }
        }
    }

    private func dAppsWithoutAccountGrouping(
        _ dApps: [ConnectionsViewState.UserWalletTab.WalletConnectDAppsSection.DApp]
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            dAppRows(dApps)
        }
    }

    private func accountSectionView(
        _ accountSection: ConnectionsViewState.UserWalletTab.WalletConnectDAppsSection.AccountSection
    ) -> some View {
        VStack(alignment: .leading, spacing: .zero) {
            accountSectionHeader(accountSection)
            dAppRows(accountSection.dApps)
        }
        .background(DesignSystem.Color.bgSecondary, in: .rect(cornerRadius: 24))
    }

    private func accountSectionHeader(
        _ accountSection: ConnectionsViewState.UserWalletTab.WalletConnectDAppsSection.AccountSection
    ) -> some View {
        HStack(spacing: 12) {
            AccountIconView(
                data: AccountModelUtils.UI.iconViewData(icon: accountSection.icon, accountName: accountSection.name),
                settings: .defaultSized
            )
            .settings(.smallSized)

            Text(accountSection.name)
                .font(token: DesignSystem.Font.captionMediumToken)
                .foregroundStyle(DesignSystem.Color.textPrimary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.top, 16)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private func dAppRows(_ dApps: [ConnectionsViewState.UserWalletTab.WalletConnectDAppsSection.DApp]) -> some View {
        ForEach(dApps) { dApp in
            Row(title: dApp.name, subtitle: dApp.domain)
                .start { remoteIconView(dApp.iconURL, fallbackIcon: DesignSystem.Icons.Globe.regular20) }
                .onTap { viewModel.handle(action: .dAppTapped(dApp.domainModel)) }
                .background(DesignSystem.Color.bgSecondary, in: .rect(cornerRadius: 24))
        }
    }

    // MARK: - Shared

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(token: DesignSystem.Font.subheadingMediumToken)
            .foregroundStyle(DesignSystem.Color.textSecondary)
            .padding(.vertical, 8)
    }

    private func loadingStubsSectionView(stubsCount: Int) -> some View {
        VStack(spacing: .zero) {
            ForEach(0 ..< stubsCount, id: \.self) { _ in
                loadingShimmerStub
            }
        }
        .background(DesignSystem.Color.bgSecondary, in: .rect(cornerRadius: 24))
    }

    private var loadingShimmerStub: some View {
        Row(.shimmer(subtitle: true))
            .start {
                Shimmer()
                    .variant(.custom(width: 40, height: 40, cornerRadius: 12))
            }
    }

    private func remoteIconView(_ iconURL: URL?, fallbackIcon: ImageType) -> some View {
        KFImage(iconURL)
            .placeholder {
                Shimmer()
            }
            .onFailureView {
                fallbackIcon.image
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundStyle(DesignSystem.Color.iconBrand)
                    .frame(width: 40, height: 40)
                    .background(DesignSystem.Color.bgStatusInfoSubtle)
            }
            .targetCache(imageCache)
            .resizable()
            .scaledToFit()
            .frame(width: 40, height: 40)
            .clipShape(.rect(cornerRadius: 12))
    }
}
