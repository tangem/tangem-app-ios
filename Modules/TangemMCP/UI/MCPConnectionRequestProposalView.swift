//
//  MCPConnectionRequestProposalView.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import Kingfisher
import TangemAssets
import TangemUI
import TangemUIUtils

struct MCPConnectionRequestProposalView: View {
    @ObservedObject var viewModel: MCPConnectionRequestProposalViewModel
    let imageCache: Kingfisher.ImageCache

    var body: some View {
        VStack(spacing: .zero) {
            VStack(spacing: 12) {
                agentAndPermissionsCard
                userWalletSelector

                if let banner = viewModel.state.pushPermissionsBanner {
                    pushPermissionsBanner(banner)
                }
            }

            buttons
        }
        .animation(.linear(duration: 0.2), value: viewModel.state.agentSummary)
        .animation(Animation.contentFrameUpdate, value: viewModel.state.pushPermissionsBanner)
    }

    private var agentAndPermissionsCard: some View {
        VStack(spacing: 16) {
            switch viewModel.state.agentSummary {
            case .loading:
                Row(.shimmer(subtitle: true))
                    .includeInnerPadding(false)
                    .start {
                        agentIcon(nil)
                    }
                    .transition(.opacity)

            case .content(let agentState):
                Row(title: agentState.name, subtitle: agentState.host)
                    .includeInnerPadding(false)
                    .start {
                        agentIcon(agentState.iconURL)
                    }
                    .transition(.opacity)
            }

            Divider()
                .frame(height: 1)
                .overlay(DesignSystem.Color.borderSecondary)

            permissionsSection
        }
        .padding(16)
        .background(DesignSystem.Color.bgSecondary)
        .clipShape(.rect(cornerRadius: 24))
    }

    private func agentIcon(_ iconURL: URL?) -> some View {
        KFImage(iconURL)
            .placeholder {
                Shimmer()
            }
            .onFailureView {
                // [REDACTED_TODO_COMMENT]
                Shimmer()
            }
            .targetCache(imageCache)
            .resizable()
            .scaledToFill()
            .frame(width: 40, height: 40)
            .clipShape(.rect(cornerRadius: 12))
    }

    private var permissionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            bulletGroup(
                label: viewModel.state.agentPermissions.grantedSection.header,
                points: viewModel.state.agentPermissions.grantedSection.permissions,
                iconAsset: DesignSystem.Icons.Checkmark.regular16,
                foregroundColor: DesignSystem.Color.iconBrand,
                backgroundColor: DesignSystem.Color.bgStatusInfoSubtle
            )

            bulletGroup(
                label: viewModel.state.agentPermissions.restrictedSection.header,
                points: viewModel.state.agentPermissions.restrictedSection.permissions,
                iconAsset: DesignSystem.Icons.Cross.regular16,
                foregroundColor: DesignSystem.Color.iconStatusError,
                backgroundColor: DesignSystem.Color.bgStatusErrorSubtle
            )
        }
    }

    private func bulletGroup(
        label: String,
        points: [String],
        iconAsset: ImageType,
        foregroundColor: Color,
        backgroundColor: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)

            VStack(spacing: 12) {
                ForEach(points, id: \.self) { point in
                    HStack(spacing: 12) {
                        iconAsset.image
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                            .foregroundStyle(foregroundColor)
                            .frame(width: 24, height: 24)
                            .background { Circle().fill(backgroundColor) }

                        Text(point)
                            .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
    }

    private var userWalletSelector: some View {
        Row(title: viewModel.state.userWalletSelector.label)
            .onTap(action: userWalletSelectorOnTapAction)
            .valueAccessory {
                HStack(spacing: 4) {
                    if let thumbnail = viewModel.state.userWalletSelector.selection.thumbnail {
                        MiniatureWalletView(type: thumbnail)
                            .frame(width: 20, height: 20)
                    }

                    Text(viewModel.state.userWalletSelector.selection.name)
                        .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textSecondary)
                }
            }
            .end {
                if viewModel.state.userWalletSelector.isSelectionAllowed {
                    DesignSystem.Icons.ChevronDown.regular16.image
                }
            }
            .disabled(!viewModel.state.userWalletSelector.isEnabled)
            .background(DesignSystem.Color.bgSecondary)
            .clipShape(.rect(cornerRadius: 24))
    }

    private var userWalletSelectorOnTapAction: (() -> Void)? {
        return viewModel.state.userWalletSelector.isSelectionAllowed
            ? { viewModel.handle(action: .userWalletSelectorTapped) }
            : nil
    }

    private func pushPermissionsBanner(_ banner: MCPConnectionRequestProposalState.PushNotificationsPermissionBanner) -> some View {
        MessageBanner(title: banner.title, description: banner.description)
            .variant(.warning)
            .primaryButton(
                MessageBannerButton(title: banner.buttonTitle) {
                    viewModel.handle(action: .openSystemSettingsButtonTapped)
                }
            )
            .transition(.move(edge: .top))
    }

    private var buttons: some View {
        HStack(spacing: 8) {
            TangemUI.Button(
                label: viewModel.state.declineButton.title,
                accessibilityLabel: nil,
                action: { viewModel.handle(action: .declineButtonTapped) }
            )
            .loading(.spinner(if: viewModel.state.declineButton.state == .loading))
            .styleType(.secondary(.default))
            .size(.x12)
            .horizontalLayout(.infinity)
            .disabled(viewModel.state.declineButton.state != .enabled)

            TangemUI.Button(
                label: viewModel.state.connectButton.title,
                accessibilityLabel: nil,
                action: { viewModel.handle(action: .connectButtonTapped) }
            )
            .loading(.spinner(if: viewModel.state.connectButton.state == .loading))
            .styleType(.primary)
            .size(.x12)
            .horizontalLayout(.infinity)
            .disabled(viewModel.state.connectButton.state != .enabled)
        }
        .padding(.top, 16)
    }
}
