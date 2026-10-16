//
//  PendingJointAccountItemView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccounts
import TangemAccessibilityIdentifiers
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

struct PendingJointAccountItemView: View {
    @ObservedObject var viewModel: PendingJointAccountItemViewModel

    private var cornerRadius: CGFloat = 14
    private var backgroundColor: Color = Colors.Background.primary

    init(viewModel: PendingJointAccountItemViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body

    var body: some View {
        SwiftUI.Button(action: viewModel.onSelect) {
            VStack(spacing: Constants.contentSpacing) {
                header

                if let action = viewModel.action {
                    actionBanner(for: action)
                }
            }
            .padding(Constants.contentPadding)
            .frame(maxWidth: .infinity)
            // Inside the label so that the background scales with the content when the plate is pressed
            .background(backgroundColor)
            .cornerRadiusContinuous(cornerRadius)
            .contentShape(.rect)
        }
        .buttonStyle(.scaled(scaleAmount: Constants.pressedScale, dimmingAmount: Constants.pressedDimming))
        .accessibilityIdentifier(AccountsAccessibilityIdentifiers.pendingJointAccountItem(accountName: viewModel.name))
    }

    // MARK: - Header

    private var header: some View {
        TwoLineRowWithIcon(
            icon: {
                AccountIconView(
                    data: viewModel.iconData.applyingLetterConfig(AccountItemConstants.letterConfig),
                    settings: AccountItemConstants.collapsedIconSettings
                )
            },
            primaryLeadingView: {
                Text(viewModel.name)
                    .style(TangemRowConstants.Style.Title.font, color: TangemRowConstants.Style.Title.color)
            },
            primaryTrailingView: {
                // Muted rather than stated the way a working account states its balance: nothing can reach the
                // account until it is activated
                Text(viewModel.balance)
                    .style(TangemRowConstants.Style.Title.font, color: DesignSystem.Color.textTertiary)
            },
            secondaryLeadingView: {
                Text(viewModel.status)
                    .style(TangemRowConstants.Style.Subtitle.font, color: TangemRowConstants.Style.Subtitle.color)
            },
            secondaryTrailingView: {
                PriceChangeView(
                    state: viewModel.priceChange,
                    showSkeletonWhenLoading: false,
                    showIconForNeutral: false,
                    useRedesignColors: true
                )
            }
        )
        .linesSpacing(Constants.linesSpacing)
    }

    // MARK: - Action banner

    private func actionBanner(for action: PendingJointAccountItemViewModel.Action) -> some View {
        HStack(spacing: Constants.actionBannerSpacing) {
            icon(for: action)
                .renderingMode(.template)
                .foregroundStyle(DesignSystem.Color.iconStatusWarning)

            Text(title(for: action))
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textPrimary)
                .lineLimit(1)

            Spacer(minLength: Constants.actionBannerSpacing)

            DesignSystem.Icons.ChevronRight.regular12.image
                .renderingMode(.template)
                .foregroundStyle(DesignSystem.Color.iconSecondary)
        }
        .padding(.horizontal, Constants.actionBannerHorizontalPadding)
        .frame(height: Constants.actionBannerHeight)
        .frame(maxWidth: .infinity)
        .background(DesignSystem.Color.bgStatusWarningSubtle)
        .cornerRadiusContinuous(Constants.actionBannerCornerRadius)
    }

    private func icon(for action: PendingJointAccountItemViewModel.Action) -> Image {
        switch action {
        case .invite: DesignSystem.Icons.UserPlus.regular16.image
        case .activate: DesignSystem.Icons.WalletCheckmark.regular16.image
        }
    }

    private func title(for action: PendingJointAccountItemViewModel.Action) -> String {
        switch action {
        case .invite: Localization.jointAccountInviteMembersToJoin
        case .activate: Localization.jointAccountActivationAccountButtonTitle
        }
    }
}

// MARK: - Setupable

extension PendingJointAccountItemView: Setupable {
    func cornerRadius(_ cornerRadius: CGFloat) -> Self {
        map { $0.cornerRadius = cornerRadius }
    }

    func backgroundColor(_ backgroundColor: Color) -> Self {
        map { $0.backgroundColor = backgroundColor }
    }
}

// MARK: - Constants

private extension PendingJointAccountItemView {
    enum Constants {
        static let contentPadding: CGFloat = 12
        static let contentSpacing: CGFloat = 12
        static let linesSpacing: CGFloat = 4

        static let actionBannerHeight: CGFloat = 32
        static let actionBannerHorizontalPadding: CGFloat = 12
        static let actionBannerSpacing: CGFloat = 8
        static let actionBannerCornerRadius: CGFloat = 20

        /// Matches the press feedback of the expandable plates it stands alongside.
        static let pressedScale: CGFloat = 0.98
        static let pressedDimming: CGFloat = 0.7
    }
}

// MARK: - Previews

/// Outlives the accounts of the previews below, which hold it weakly.
private let previewJointAccountDelegate = JointAccountModelDelegateMock()

private let previewInviteURL = URL(string: "https://tangem.com/joint-account/join/preview")

private func previewJointAccount(
    status: JointAccountStatus,
    membersCount: Int,
    takenSlotsCount: Int,
    isCreatorDevice: Bool = false
) -> any JointAccountModel {
    CommonJointAccountModel(
        cryptoAccount: CryptoAccountModelMock(isMainAccount: false, onArchive: { _ in }),
        derivationIdentity: CryptoAccountDerivationIdentity(derivationIndex: 1, type: .joint),
        accountPolicy: JointAccountPolicy(membersCount: membersCount, signersCount: 2),
        accountStatus: status,
        operationsService: JointAccountOperationsServiceMock(),
        pendingOperationsProvider: JointAccountPendingOperationsProviderMock(),
        membersService: JointAccountMembersServiceMock(
            slots: (0 ..< max(membersCount, takenSlotsCount)).map { index -> JointAccountSlot in
                guard index < takenSlotsCount else {
                    return .empty(invite: previewInviteURL.map { JointAccountInvite(id: "invite-\(index)", url: $0) })
                }

                return .member(
                    JointAccountMember(
                        name: "Member \(index)",
                        address: "0x0000000000000000000000000000000000000000",
                        role: index == 0 ? .creator : .member(inviteId: nil)
                    )
                )
            },
            isCreatorDevice: isCreatorDevice
        ),
        delegate: previewJointAccountDelegate
    )
}

#Preview {
    ZStack {
        DesignSystem.Color.bgPrimary.ignoresSafeArea()

        VStack(spacing: 8) {
            PendingJointAccountItemView(
                viewModel: PendingJointAccountItemViewModel(
                    jointAccount: previewJointAccount(status: .pending, membersCount: 5, takenSlotsCount: 1),
                    onTap: {}
                )
            )
            .cornerRadius(24)
            .backgroundColor(DesignSystem.Color.bgSecondary)

            PendingJointAccountItemView(
                viewModel: PendingJointAccountItemViewModel(
                    jointAccount: previewJointAccount(
                        status: .confirming(safeAddress: "0x8f3a1c5e7b9d0246a8c0e2b4d6f8a0c2e4b6c21b"),
                        membersCount: 3,
                        takenSlotsCount: 3,
                        isCreatorDevice: true
                    ),
                    onTap: {}
                )
            )
            .cornerRadius(24)
            .backgroundColor(DesignSystem.Color.bgSecondary)
        }
        .padding(12)
    }
}
