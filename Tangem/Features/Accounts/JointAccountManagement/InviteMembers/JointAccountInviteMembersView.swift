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

struct JointAccountInviteMembersView: View {
    @ObservedObject var viewModel: JointAccountInviteMembersViewModel

    var body: some View {
        ZStack {
            DesignSystem.Color.bgPrimary.ignoresSafeArea()

            GroupedScrollView(contentType: .plain(alignment: .leading, spacing: 24)) {
                titleView

                takenSlotsSection

                if viewModel.content.freeSlots.isNotEmpty {
                    freeSlotsSection
                }
            }
        }
        .topNavigation(leading: .none, actions: .one(detailsAction), onClose: viewModel.onCloseTap)
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
            accessory: .info(action: { viewModel.onMemberInfoTap(memberIndex: member.memberIndex) })
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
            title: Localization.jointAccountInviteMembersNewMember,
            subtitle: Localization.jointAccountInviteMembersNotInvited,
            accessory: accessory(for: freeSlot)
        )
    }

    private func accessory(for freeSlot: JointAccountInviteMembersViewModel.FreeSlotViewData) -> JointAccountMemberRow.Accessory {
        guard let inviteURL = freeSlot.inviteURL else {
            return .empty
        }

        return .invite(action: { viewModel.onInviteTap(inviteURL: inviteURL) })
    }
}
