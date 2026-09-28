//
//  JointAccountInviteMembersView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemFoundation
import TangemLocalization
import TangemUI
import TangemUIUtils

struct JointAccountInviteMembersView: View {
    @ObservedObject var viewModel: JointAccountInviteMembersViewModel

    var body: some View {
        ZStack {
            DesignSystem.Color.bgPrimary.ignoresSafeArea()

            VStack(spacing: .zero) {
                GroupedScrollView(contentType: .plain(alignment: .leading, spacing: 24)) {
                    titleView

                    takenSlotsSection

                    if viewModel.content.freeSlots.isNotEmpty {
                        freeSlotsSection
                    }
                }

                if viewModel.content.isActivationAvailable {
                    activateButton
                }
            }
        }
        .topNavigation(leading: .none, actions: actions, onClose: viewModel.onCloseTap)
        .onWillAppear(perform: viewModel.onWillAppear)
        .onWillDisappear(perform: viewModel.onWillDisappear)
        .alert(item: $viewModel.alert, content: { $0.alert })
        .confirmationDialog(
            Localization.accountDetailsArchiveJointDescription,
            isPresented: $viewModel.isArchiveConfirmationPresented,
            titleVisibility: .visible
        ) {
            SwiftUI.Button(Localization.accountDetailsArchive, role: .destructive) {
                viewModel.onArchiveConfirmTap()
            }
        }
    }

    /// The menu holds nothing but archiving, so a member who cannot archive gets no menu rather than an empty one.
    private var actions: TopNavigation.Actions? {
        guard viewModel.content.canArchive else {
            return nil
        }

        return .one(detailsAction)
    }

    private var activateButton: some View {
        TangemUI.Button(
            label: Localization.jointAccountActivationAccountButtonTitle,
            accessibilityLabel: Localization.jointAccountActivationAccountButtonTitle,
            action: viewModel.onActivateTap
        )
        .styleType(.default)
        .size(.x12)
        .horizontalLayout(.infinity)
        .loading(.spinner(if: viewModel.isActivating))
        .padding(.horizontal, Constants.activateButtonHorizontalPadding)
        .padding(.vertical, Constants.activateButtonVerticalPadding)
    }

    private var detailsAction: TopNavigation.Action {
        TopNavigation.Action(
            icon: DesignSystem.Icons.DotsHorizontal.regular20,
            accessibilityLabel: Localization.commonMore,
            menu: [
                TopNavigation.MenuItem(
                    title: Localization.accountDetailsArchive,
                    role: .destructive,
                    action: viewModel.onArchiveTap
                ),
            ]
        )
    }

    private var titleView: some View {
        JointAccountHeaderTitle(
            title: Localization.jointAccountInviteMembersTitle,
            subtitle: Localization.jointAccountInviteMembersSubtitle(
                viewModel.content.joinedMembersCount,
                viewModel.content.totalMembersCount
            )
        )
        .padding(.top, 12)
        .padding(.horizontal, 8)
    }

    private var takenSlotsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            safetyBanner

            ForEach(viewModel.content.members) { member in
                joinedMemberView(member)
            }
        }
    }

    private var safetyBanner: some View {
        MessageBanner(
            title: Localization.jointAccountInviteMembersSafetyTitle,
            description: Localization.jointAccountInviteMembersSafetySubtitle
        )
        .variant(.info)
        .slotStart {
            DesignSystem.Icons.ShieldCheckmark.filled24.image
                .renderingMode(.template)
                .foregroundStyle(DesignSystem.Color.iconStatusInfo)
        }
        .slotEnd {
            DesignSystem.Icons.ChevronRight.regular20.image
                .renderingMode(.template)
                .foregroundStyle(DesignSystem.Color.iconSecondary)
        }
        .onTap(viewModel.onSafetyBannerTap)
    }

    private func joinedMemberView(_ member: JointAccountInviteMembersViewModel.MemberViewData) -> some View {
        JointAccountMemberRow(
            avatar: .member(member.icon),
            title: member.name,
            subtitle: member.role,
            accessory: .info(action: { viewModel.onMemberInfoTap(member) })
        )
    }

    private var freeSlotsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Localization.jointAccountInviteMembersOtherMembers)
                .font(token: DesignSystem.Font.captionMediumToken)
                .foregroundStyle(DesignSystem.Color.textSecondary)
                .padding(.horizontal, 8)

            ForEach(viewModel.content.freeSlots) { freeSlot in
                freeSlotView(freeSlot)
            }
        }
    }

    private func freeSlotView(_ freeSlot: JointAccountInviteMembersViewModel.FreeSlotViewData) -> some View {
        JointAccountMemberRow(
            avatar: .emptySlot,
            title: Localization.jointAccountInviteMembersMember,
            subtitle: Localization.jointAccountInviteMembersNotInvited,
            accessory: accessory(for: freeSlot)
        )
    }

    private func accessory(for freeSlot: JointAccountInviteMembersViewModel.FreeSlotViewData) -> JointAccountMemberRow.Accessory {
        guard let inviteURL = freeSlot.invite?.url else {
            return .empty
        }

        return .invite(action: { viewModel.onInviteTap(inviteURL: inviteURL) })
    }
}

// MARK: - Constants

private extension JointAccountInviteMembersView {
    enum Constants {
        static let activateButtonHorizontalPadding: CGFloat = 16
        static let activateButtonVerticalPadding: CGFloat = 12
    }
}
