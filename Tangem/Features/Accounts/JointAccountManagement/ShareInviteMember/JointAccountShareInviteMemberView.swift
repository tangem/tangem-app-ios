//
//  JointAccountShareInviteMemberView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

struct JointAccountShareInviteMemberView: View {
    let viewModel: JointAccountShareInviteMemberViewModel

    var body: some View {
        VStack(spacing: 0) {
            points

            messageCard
                .padding(16)
        }
        .frame(maxWidth: .infinity)
        .footer { Footer(.buttons(primary: shareButton)) }
    }

    private var points: some View {
        VStack(spacing: 0) {
            ForEach(Point.allCases, id: \.self) { point in
                pointRow(point)
            }
        }
        .padding(.horizontal, 8)
    }

    private func pointRow(_ point: Point) -> some View {
        Row(title: point.title, subtitle: point.subtitle)
            .subtitleLineLimit(nil)
            .verticalAlignment(.top)
            .includeInnerPadding(false)
            .start {
                point.icon.image
                    .renderingMode(.template)
                    .foregroundStyle(DesignSystem.Color.iconPrimary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
    }

    private var messageCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Localization.jointAccountInviteMemberMessageLabel)
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)

            VStack(alignment: .leading, spacing: 0) {
                Text(viewModel.message)
                    .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)

                Text(viewModel.link)
                    .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                    .clipped()
                    .mask(linkFade)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(DesignSystem.Color.bgTransparentOnMaterialPrimary, in: messageCardShape)
        .contentShape(messageCardShape)
        .onTapGesture(perform: viewModel.onMessageTap)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint(Localization.commonCopy)
    }

    private var messageCardShape: some Shape {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
    }

    private var linkFade: some View {
        LinearGradient(
            stops: [
                .init(color: .black, location: 0),
                .init(color: .black, location: 0.85),
                .init(color: .clear, location: 1),
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private var shareButton: TangemUI.Button {
        TangemUI.Button(
            label: Localization.commonShare,
            accessibilityLabel: Localization.commonShare,
            action: viewModel.onShareTap
        )
        .iconEnd(DesignSystem.Icons.ShareIos.regular24)
        .styleType(.primary)
    }
}

// MARK: - Point

private extension JointAccountShareInviteMemberView {
    enum Point: CaseIterable {
        case oneLink
        case joinsFirst
        case verifies

        var icon: ImageType {
            switch self {
            case .oneLink: DesignSystem.Icons.UserPlus.regular20
            case .joinsFirst: DesignSystem.Icons.Users.regular20
            case .verifies: DesignSystem.Icons.Success.regular20
            }
        }

        var title: String {
            switch self {
            case .oneLink: Localization.jointAccountInviteMemberOneLinkTitle
            case .joinsFirst: Localization.jointAccountInviteMemberJoinsFirstTitle
            case .verifies: Localization.jointAccountInviteMemberVerifiesTitle
            }
        }

        var subtitle: String {
            switch self {
            case .oneLink: Localization.jointAccountInviteMemberOneLinkSubtitle
            case .joinsFirst: Localization.jointAccountInviteMemberJoinsFirstSubtitle
            case .verifies: Localization.jointAccountInviteMemberVerifiesSubtitle
            }
        }
    }
}

// MARK: - Previews

#Preview {
    Color.clear
        .modal(
            isPresented: .constant(true),
            navigation: .title(Localization.jointAccountInviteMemberTitle),
            content: {
                JointAccountShareInviteMemberView(
                    viewModel: JointAccountShareInviteMemberViewModel(
                        accountName: "Family savings",
                        url: URL(string: "https://tangem.com/joint-account/join/0EB4F7E48E9DC3F")!,
                        coordinator: nil
                    )
                )
            }
        )
}
