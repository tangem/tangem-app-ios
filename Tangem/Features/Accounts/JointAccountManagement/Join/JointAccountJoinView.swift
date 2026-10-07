//
//  JointAccountJoinView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import BlockchainSdk
import TangemAccounts
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

struct JointAccountJoinView: View {
    @ObservedObject var viewModel: JointAccountJoinViewModel

    var body: some View {
        ZStack {
            DesignSystem.Color.bgPrimary.ignoresSafeArea()

            switch viewModel.state {
            case .loading:
                ProgressView()

            case .loaded(let content):
                invite(content)

            case .invalidInvite:
                JointAccountInvalidInviteView(
                    onCloseTap: viewModel.onCloseTap,
                    onGotItTap: viewModel.onCloseTap
                )

            case .loadFailed(let isRetrying):
                JointAccountInviteLoadFailedView(
                    isRetrying: isRetrying,
                    onCloseTap: viewModel.onCloseTap,
                    onRetryTap: viewModel.onRetryTap
                )
            }
        }
        .ignoresSafeArea(.keyboard)
    }

    private func invite(_ content: JointAccountJoinViewModel.Content) -> some View {
        ZStack(alignment: .top) {
            glow(content)

            VStack(spacing: .zero) {
                accountIcon(content).infinityFrame()

                VStack(spacing: .zero) {
                    mainContent(content)

                    footer
                }
                .padding(.horizontal, Constants.contentHorizontalPadding)
            }
        }
        .topNavigation(leading: .none, onClose: viewModel.onCloseTap)
    }

    private func glow(_ content: JointAccountJoinViewModel.Content) -> some View {
        RoundedRectangle(cornerRadius: Constants.glowCornerRadius, style: .continuous)
            .fill(content.accountIconViewData.backgroundColor)
            .frame(height: Constants.glowHeight)
            .padding(.horizontal, Constants.glowHorizontalPadding)
            .blur(radius: Constants.glowBlurRadius)
            .opacity(Constants.glowOpacity)
            .offset(y: -Constants.glowHeight / 2)
    }

    private func accountIcon(_ content: JointAccountJoinViewModel.Content) -> some View {
        AccountIconView(data: content.accountIconViewData, settings: .extraLargeSized)
            .overlay(accountIconHighlight)
            .clipShape(accountIconShape)
            .overlay {
                accountIconShape
                    .strokeBorder(
                        DesignSystem.Color.borderPrimary,
                        lineWidth: Constants.accountIconBorderWidth
                    )
            }
    }

    private var accountIconHighlight: some View {
        LinearGradient(
            colors: [
                .clear,
                Color.white.opacity(Constants.accountIconHighlightOpacity),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var accountIconShape: RoundedRectangle {
        RoundedRectangle(
            cornerRadius: Constants.accountIconSize * Constants.accountIconCornerRadiusRatio,
            style: .continuous
        )
    }

    private func mainContent(_ content: JointAccountJoinViewModel.Content) -> some View {
        VStack(alignment: .leading, spacing: .zero) {
            JointAccountHeaderTitle(title: content.title, subtitle: content.subtitle)
                .padding(.vertical, Constants.titleVerticalPadding)
                .padding(.horizontal, Constants.mainContentHorizontalPadding)

            rows(content)
        }
    }

    @ViewBuilder
    private func rows(_ content: JointAccountJoinViewModel.Content) -> some View {
        Row(title: Localization.jointAccountInviteMembersCreator, value: content.creatorName)
            .contentLead(.end)
            .overrideTextColors(.init(value: DesignSystem.Color.textSecondary))
            .valueAccessory {
                DesignSystem.Icons.Info.regular20.image
                    .renderingMode(.template)
                    .foregroundStyle(DesignSystem.Color.iconSecondary)
            }
            .showDivider(true)
            .onTap(viewModel.onCreatorInfoTap)

        Row(title: Localization.commonWallet)
            .contentLead(.end)
            .valueAccessory {
                HStack(spacing: Constants.walletValueSpacing) {
                    if let walletThumbnailType = viewModel.walletThumbnailType {
                        MiniatureWalletView(type: walletThumbnailType)
                            .frame(size: Constants.walletThumbnailSize)
                    }

                    Text(viewModel.walletName)
                        .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textSecondary)
                        .lineLimit(1)

                    if content.isWalletSelectionAvailable {
                        DesignSystem.Icons.ChevronDown.regular16.image
                            .renderingMode(.template)
                            .foregroundStyle(DesignSystem.Color.iconSecondary)
                    }
                }
            }
            .if(content.isWalletSelectionAvailable) {
                $0.onTap(viewModel.onWalletTap)
            }
    }

    private var footer: some View {
        TangemUI.Button(label: Localization.commonContinue, accessibilityLabel: nil) {
            viewModel.onContinueTap()
        }
        .styleType(.default)
        .horizontalLayout(.infinity)
        .size(.x12)
        .padding(.vertical, Constants.footerVerticalPadding)
    }
}

// MARK: - Constants

private extension JointAccountJoinView {
    enum Constants {
        static let glowCornerRadius: CGFloat = 138
        static let glowHeight: CGFloat = 422
        static let glowHorizontalPadding: CGFloat = 13
        static let glowBlurRadius: CGFloat = 80
        static let glowOpacity: CGFloat = 0.2

        static let accountIconSize: CGFloat = 128
        static let accountIconCornerRadiusRatio: CGFloat = 0.28
        static let accountIconBorderWidth: CGFloat = 2
        static let accountIconHighlightOpacity: CGFloat = 0.2

        static let contentHorizontalPadding: CGFloat = 16
        static let mainContentHorizontalPadding: CGFloat = 8
        static let titleVerticalPadding: CGFloat = 12

        static let walletValueSpacing: CGFloat = 4
        static let walletThumbnailSize = CGSize(bothDimensions: 20)

        static let footerVerticalPadding: CGFloat = 12
    }
}

// MARK: - Previews

#if DEBUG
private struct JointAccountsNetworkServicePreviewStub: JointAccountsNetworkService {
    func createJointAccount(blob: JointAccountCreationBlob) async throws -> JointAccountCreationResult {
        throw CancellationError()
    }

    func getJointAccounts(knownETag: String?) async throws -> JointAccountsRemoteState { .changed([], eTag: nil) }

    func getInvitePreview(inviteId: String) async throws -> JointAccountInvitePreview {
        JointAccountInvitePreview(
            config: JointAccountSignedConfig(
                name: "Family savings",
                icon: AccountModel.CompositeIcon.Name.safe.rawValue,
                iconColor: CompositeIconColor.candyGrapeFizz.rawValue,
                membersCount: 5,
                threshold: 2
            ),
            creator: JointAccountInvitePreview.Creator(
                name: "Isaac",
                address: "0xBef7B36845000000000000ac4e6752A9cE000000"
            )
        )
    }

    func joinJointAccount(blob: JointAccountJoinBlob) async throws -> RemoteJointAccount {
        throw CancellationError()
    }

    func activateJointAccount(blob: JointAccountActivationBlob) async throws -> RemoteJointAccount {
        throw CancellationError()
    }

    func createOperation(_ request: JointAccountOperationRequest) async throws -> JointAccountOperation {
        throw CancellationError()
    }

    func signOperation(id: String, safeTransaction: SafeTransaction, signature: Data) async throws -> JointAccountOperation {
        throw CancellationError()
    }

    func rejectOperation(id: String) async throws -> JointAccountOperation? {
        throw CancellationError()
    }
}

#Preview {
    NavigationStack {
        JointAccountJoinView(
            viewModel: JointAccountJoinViewModel(
                inviteId: "preview-invite",
                networkService: JointAccountsNetworkServicePreviewStub(),
                userWalletModels: FakeUserWalletModel.allFakeWalletModels,
                coordinator: nil
            )
        )
    }
}
#endif
