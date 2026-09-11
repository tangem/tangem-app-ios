//
//  JointAccountInviteMembersView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

struct JointAccountInviteMembersView: View {
    @ObservedObject var viewModel: JointAccountInviteMembersViewModel

    var body: some View {
        ZStack {
            DesignSystem.Color.bgPrimary.ignoresSafeArea()

            GroupedScrollView(contentType: .plain(alignment: .leading, spacing: 24)) {
                titleView

                creatorSection

                otherMembersSection
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
                viewModel.joinedMembersCount,
                viewModel.totalMembersCount
            )
        )
        .padding(.top, 12)
        .padding(.horizontal, 8)
    }

    private var creatorSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            safetyBanner

            creatorView
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

    private var creatorView: some View {
        JointAccountMemberRow(
            avatar: .member(viewModel.creatorIconViewData),
            title: viewModel.creatorName,
            subtitle: Localization.jointAccountInviteMembersCreator,
            accessory: .info(action: viewModel.onCreatorInfoTap)
        )
    }

    private var otherMembersSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Localization.jointAccountInviteMembersOtherMembers)
                .font(token: DesignSystem.Font.captionMediumToken)
                .foregroundStyle(DesignSystem.Color.textSecondary)
                .padding(.horizontal, 8)

            ForEach(0 ..< viewModel.invitableSlotsCount, id: \.self) { _ in
                invitableSlotView
            }
        }
    }

    private var invitableSlotView: some View {
        JointAccountMemberRow(
            avatar: .emptySlot,
            title: Localization.jointAccountInviteMembersNewMember,
            subtitle: Localization.jointAccountInviteMembersNotInvited,
            accessory: .invite(action: viewModel.onInviteTap)
        )
    }
}
