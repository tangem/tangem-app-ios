//
//  RecentRecipientsContentView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccessibilityIdentifiers
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

struct RecentRecipientsContentView: View {
    let recipients: [RecentRecipientItem]
    let onRecipientTap: (String) -> Void

    var body: some View {
        ScrollView {
            LazyVStack(spacing: .zero, pinnedViews: [.sectionHeaders]) {
                Section {
                    ForEach(recipients) { recipient in
                        Row(title: recipient.name, subtitle: recipient.subtitle)
                            .start { monogram(recipient.monogram) }
                            .onTap { onRecipientTap(recipient.id) }
                            .accessibilityIdentifier(TangemPayOfframpAccessibilityIdentifiers.recipientsRow)
                    }
                } header: {
                    if !recipients.isEmpty {
                        Text(Localization.tangempayWithdrawBankRecipientsRecentsTitle)
                            .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, Constants.horizontalPadding)
                            .padding(.vertical, Constants.titleVerticalPadding)
                            .background(DesignSystem.Color.bgPrimary)
                    }
                }
            }
        }
        .background {
            DesignSystem.Color.bgPrimary.ignoresSafeArea()
        }
        .overlay {
            if recipients.isEmpty {
                emptyView
            }
        }
    }
}

// MARK: - Subviews

private extension RecentRecipientsContentView {
    func monogram(_ text: String) -> some View {
        Text(text)
            .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textSecondary)
            .frame(width: Constants.monogramSide, height: Constants.monogramSide)
            .background(DesignSystem.Color.bgTertiary, in: Circle())
    }

    var emptyView: some View {
        VStack(spacing: Constants.emptyViewSpacing) {
            DesignSystem.Color.bgSecondary
                .frame(width: Constants.emptyIconBackgroundSide, height: Constants.emptyIconBackgroundSide)
                .overlay {
                    DesignSystem.Icons.Binoculars.regular20.image
                        .renderingMode(.template)
                        .foregroundStyle(DesignSystem.Color.iconSecondary)
                }
                .clipShape(Circle())

            Text(Localization.tangempayWithdrawBankRecipientsSearchEmpty)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                .multilineTextAlignment(.center)
                .accessibilityIdentifier(TangemPayOfframpAccessibilityIdentifiers.recipientsSearchEmpty)
        }
        .padding(.horizontal, Constants.horizontalPadding)
        .infinityFrame()
    }
}

// MARK: - Constants

private extension RecentRecipientsContentView {
    enum Constants {
        static let horizontalPadding: CGFloat = 16
        static let titleVerticalPadding: CGFloat = 8
        static let monogramSide: CGFloat = 40
        static let emptyViewSpacing: CGFloat = 12
        static let emptyIconBackgroundSide: CGFloat = 40
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Full list") {
    RecentRecipientsContentView(
        recipients: RecentRecipientItem.previewList,
        onRecipientTap: { _ in }
    )
}

#Preview("Filtered list") {
    RecentRecipientsContentView(
        recipients: Array(RecentRecipientItem.previewList.prefix(1)),
        onRecipientTap: { _ in }
    )
}

#Preview("Empty list") {
    RecentRecipientsContentView(
        recipients: [],
        onRecipientTap: { _ in }
    )
}
#endif
