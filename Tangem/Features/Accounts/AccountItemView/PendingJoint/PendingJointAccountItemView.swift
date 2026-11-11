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
    private var backgroundColor: Color = DesignSystem.Color.bgSecondary

    init(viewModel: PendingJointAccountItemViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body

    var body: some View {
        SwiftUI.Button(action: viewModel.onSelect) {
            VStack(spacing: .zero) {
                header
                    .padding(Constants.contentPadding)

                if let action = viewModel.action {
                    actionBanner(for: action)
                        .allowsHitTesting(false)
                        .padding([.horizontal, .bottom], Constants.contentPadding)
                }
            }
            .frame(maxWidth: .infinity)
            // Inside the label so that the background scales with the content when the plate is pressed
            .background(backgroundColor)
            .cornerRadiusContinuous(cornerRadius)
            .contentShape(.rect)
        }
        .buttonStyle(.scaled(dimmingAmount: 0.7))
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
                    showIconForNeutral: false
                )
            }
        )
        .linesSpacing(Constants.linesSpacing)
    }

    // MARK: - Action banner

    private func actionBanner(for action: PendingJointAccountItemViewModel.Action) -> some View {
        ActionMessage(title(for: action), icon: icon(for: action), action: viewModel.onSelect)
            .variant(.warning)
    }

    private func icon(for action: PendingJointAccountItemViewModel.Action) -> ImageType {
        switch action {
        case .invite: DesignSystem.Icons.UserPlus.regular16
        case .confirm: DesignSystem.Icons.Success.filled16
        case .waitingForMembers, .waitingForConfirmations: DesignSystem.Icons.Clock.regular16
        }
    }

    private func title(for action: PendingJointAccountItemViewModel.Action) -> String {
        switch action {
        case .invite: Localization.jointAccountInviteMembersToJoin
        case .confirm: Localization.jointAccountConfirmSharedAddress
        case .waitingForMembers(let count): Localization.jointAccountMainWaitingMembers(count)
        case .waitingForConfirmations(let count): Localization.jointAccountMainWaitingConfirmations(count)
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
        static let linesSpacing: CGFloat = 4
    }
}

// MARK: - Previews

/// Outlives the accounts of the previews below, which hold it weakly.
private let previewJointAccountDelegate = JointAccountModelDelegateMock()

private let previewCreator = JointAccountMember(
    name: "Member 0",
    address: "0x0000000000000000000000000000000000000000",
    role: .creator,
    isMe: false,
    signature: nil
)

private func previewJointAccount(
    status: JointAccountStatus,
    membersCount: Int,
    takenSlotsCount: Int,
    isCreator: Bool = false,
    confirmedCount: Int = 0
) -> any JointAccountModel {
    CommonJointAccountModel(
        cryptoAccount: CryptoAccountModelMock(isMainAccount: false, onArchive: { _ in }),
        derivationIdentity: CryptoAccountDerivationIdentity(derivationIndex: 1, type: .joint),
        accountPolicy: JointAccountPolicy(membersCount: membersCount, signersCount: 2),
        statusProvider: JointAccountStatusProviderStub(status: status),
        operationsService: JointAccountOperationsServiceMock(),
        pendingOperationsProvider: JointAccountPendingOperationsProviderMock(),
        membersService: JointAccountMembersServiceMock(
            slots: (0 ..< max(membersCount, takenSlotsCount)).map { index -> JointAccountSlot in
                guard index < takenSlotsCount else {
                    let slot = JointAccountMemberSlotID(index)

                    return .empty(slot, isCreator ? .invitable : .notInvitable)
                }

                return .member(
                    JointAccountMember(
                        name: "Member \(index)",
                        address: "0x0000000000000000000000000000000000000000",
                        role: index == 0 ? .creator : .member,
                        isMe: index == 0 && isCreator,
                        signature: index < confirmedCount ? "0x" : nil
                    ),
                    .joined
                )
            }
        ),
        finishedOperationsWalletUpdater: JointAccountFinishedOperationsWalletUpdater(
            pendingOperationsProvider: JointAccountPendingOperationsProviderMock(),
            walletModelsManager: WalletModelsManagerMock(),
            historyDeltaSyncing: MockJointOperationsHistorySyncService()
        ),
        userRoleService: JointAccountUserRoleServiceMock(creator: isCreator),
        delegate: previewJointAccountDelegate
    )
}

private let previewSafeAddress = "0x8f3a1c5e7b9d0246a8c0e2b4d6f8a0c2e4b6c21b"

private let previewJointAccounts: [any JointAccountModel] = [
    previewJointAccount(status: .pending, membersCount: 5, takenSlotsCount: 1, isCreator: true),
    previewJointAccount(status: .pending, membersCount: 5, takenSlotsCount: 2),
    previewJointAccount(
        status: .confirming(safeAddress: previewSafeAddress),
        membersCount: 3,
        takenSlotsCount: 3,
        isCreator: true
    ),
    previewJointAccount(
        status: .confirming(safeAddress: previewSafeAddress),
        membersCount: 3,
        takenSlotsCount: 3,
        isCreator: true,
        confirmedCount: 1
    ),
]

#Preview {
    ZStack {
        DesignSystem.Color.bgPrimary.ignoresSafeArea()

        VStack(spacing: 8) {
            ForEach(indexed: previewJointAccounts, id: \.0) { _, jointAccount in
                PendingJointAccountItemView(viewModel: PendingJointAccountItemViewModel(jointAccount: jointAccount, onTap: {}))
                    .cornerRadius(24)
                    .backgroundColor(DesignSystem.Color.bgSecondary)
            }
        }
        .padding(12)
    }
}
