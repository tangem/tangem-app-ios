//
//  TransferConfirmationContentView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemPay
import TangemUI
import TangemUIUtils

struct TransferConfirmationContentView: View {
    let state: State
    let action: (Action) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: .zero) {
                VStack(spacing: Constants.sectionSpacing) {
                    amountCard

                    railRow
                }
                .padding(.vertical, 12)

                summarySections
                    .padding(.vertical, 12)
            }
            .padding(.top, Constants.topPadding)
            .padding(.horizontal, Constants.horizontalPadding)
            .padding(.bottom, Constants.bottomPadding)
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .offrampBottomBar { bottomBar }
    }
}

// MARK: - Amount card

private extension TransferConfirmationContentView {
    var amountCard: some View {
        SwiftUI.Button {
            action(.editTap(.amount))
        } label: {
            VStack(alignment: .leading, spacing: Constants.amountCardSpacing) {
                amountHeader

                amountBody
            }
            .padding(Constants.cardPadding)
            .background(DesignSystem.Color.bgSecondary)
            .cornerRadiusContinuous(Constants.cardCornerRadius)
        }
        .buttonStyle(.plain)
    }

    var amountHeader: some View {
        HStack(spacing: Constants.amountHeaderSpacing) {
            // [REDACTED_TODO_COMMENT]
            Text("From")

            Assets.Visa.accountAvatar.image
                .resizable()
                .scaledToFit()
                .frame(width: Constants.accountAvatarSide, height: Constants.accountAvatarSide)

            // [REDACTED_TODO_COMMENT]
            Text("Payment account")

            Spacer(minLength: Constants.amountHeaderSpacing)

            Text(state.balanceText)
        }
        .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
        .lineLimit(1)
    }

    var amountBody: some View {
        HStack(alignment: .center, spacing: Constants.amountToTokenSpacing) {
            Text(state.amountText)
                .style(DesignSystem.Font.displayMediumToken, color: DesignSystem.Color.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(Constants.amountMinimumScaleFactor)

            Spacer(minLength: Constants.amountToTokenSpacing)

            if let token = state.token {
                VStack(spacing: Constants.tokenIconToSymbolSpacing) {
                    TokenIconV2(tokenIconInfo: token.tokenIconInfo, size: .size40)

                    Text(token.symbol)
                        .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                }
            }
        }
    }
}

// MARK: - Rail row

private extension TransferConfirmationContentView {
    @ViewBuilder
    var railRow: some View {
        if let rail = state.rail {
            SwiftUI.Button {
                action(.editTap(.amount))
            } label: {
                railContent(rail)
            }
            .buttonStyle(.plain)
        }
    }

    func railContent(_ rail: TransferInputRailItem) -> some View {
        HStack(spacing: .zero) {
            HStack(spacing: Constants.railTitleSpacing) {
                rail.icon.image
                    .resizable()
                    .scaledToFit()
                    .frame(width: Constants.railIconSide, height: Constants.railIconSide)

                Text(rail.title)
                    .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
            }

            Spacer()

            HStack(spacing: Constants.railValueSpacing) {
                Badge(label: rail.etaText, accessibilityLabel: nil)

                Text(rail.feeText)
                    .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
            }
        }
        .padding(.vertical, Constants.railVerticalPadding)
        .padding(.horizontal, Constants.railHorizontalPadding)
        .background(DesignSystem.Color.bgSecondary)
        .clipShape(Capsule(style: .circular))
    }
}

// MARK: - Summary sections

private extension TransferConfirmationContentView {
    var summarySections: some View {
        VStack(alignment: .leading, spacing: Constants.sectionSpacing) {
            ForEach(state.sections) { section in
                VStack(alignment: .leading, spacing: .zero) {
                    if let header = section.header {
                        Text(header)
                            .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                            .padding(.vertical, Constants.sectionHeaderVerticalPadding)
                            .padding(.horizontal, Constants.sectionHeaderHorizontalPadding)
                    }

                    sectionCard(for: section)
                }
            }
        }
    }

    @ViewBuilder
    func sectionCard(for section: TransferConfirmationSection) -> some View {
        if let editTarget = section.editTarget {
            SwiftUI.Button {
                action(.editTap(editTarget))
            } label: {
                card(for: section)
            }
            .buttonStyle(.plain)
        } else {
            card(for: section)
        }
    }

    func card(for section: TransferConfirmationSection) -> some View {
        VStack(spacing: .zero) {
            ForEach(section.rows) { row in
                TransferConfirmationSummaryRow(title: row.title, value: row.value)

                if row.id != section.rows.last?.id {
                    Separator(height: .minimal, color: DesignSystem.Color.borderSecondary)
                }
            }
        }
        .padding(.horizontal, Constants.cardPadding)
        .background(DesignSystem.Color.bgSecondary)
        .cornerRadiusContinuous(Constants.cardCornerRadius)
    }
}

// MARK: - Bottom bar

private extension TransferConfirmationContentView {
    var bottomBar: some View {
        VStack(spacing: Constants.bottomBarSpacing) {
            if let footerNote = state.footerNote {
                Text(footerNote)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textTertiary)
                    .multilineTextAlignment(.center)
            }

            sendButton
        }
    }

    var sendButton: some View {
        TangemUI.Button(
            // [REDACTED_TODO_COMMENT]
            label: "Send",
            accessibilityLabel: nil,
            action: { action(.sendTap) }
        )
        .iconEnd(state.sendButtonIcon)
        .size(.x12)
        .styleType(.default)
        .horizontalLayout(.infinity)
        .disabled(!state.isSendEnabled)
    }
}

// MARK: - Constants

private extension TransferConfirmationContentView {
    enum Constants {
        static let sectionSpacing: CGFloat = 8
        static let topPadding: CGFloat = 12
        static let horizontalPadding: CGFloat = 16
        static let bottomPadding: CGFloat = 8
        static let cardPadding: CGFloat = 16
        static let cardCornerRadius: CGFloat = 24
        static let amountCardSpacing: CGFloat = 16
        static let amountHeaderSpacing: CGFloat = 4
        static let amountToTokenSpacing: CGFloat = 12
        static let amountMinimumScaleFactor: CGFloat = 0.5
        static let accountAvatarSide: CGFloat = 16
        static let tokenIconToSymbolSpacing: CGFloat = 2
        static let accessorySpacing: CGFloat = 12
        static let railIconSide: CGFloat = 20
        static let railTitleSpacing: CGFloat = 12
        static let railValueSpacing: CGFloat = 8
        static let railVerticalPadding: CGFloat = 12
        static let railHorizontalPadding: CGFloat = 16
        static let sectionHeaderVerticalPadding: CGFloat = 8
        static let sectionHeaderHorizontalPadding: CGFloat = 16
        static let bottomBarSpacing: CGFloat = 8
    }
}

// MARK: - State

extension TransferConfirmationContentView {
    struct State {
        let balanceText: String
        let amountText: String
        let token: TransferInputTokenItem?
        let rail: TransferInputRailItem?
        let sections: [TransferConfirmationSection]
        let footerNote: String?
        let sendButtonIcon: ImageType?
        let isSendEnabled: Bool
    }
}

// MARK: - Action

extension TransferConfirmationContentView {
    enum Action {
        case editTap(TransferConfirmationEditTarget)
        case sendTap
    }
}

// MARK: - Previews

#if DEBUG
private enum TransferConfirmationPreview {
    static let country = TangemPayGeoCountry(
        code: "US",
        name: "United States of America",
        flagUrl: nil,
        suggested: true,
        hasRegions: true
    )

    static let region = TangemPayGeoRegion(code: "US-NC", name: "North Carolina", suggested: false)

    static let personalDetails = TangemPayOfframpPersonalDetails(
        name: .individual(firstName: "Saburo", lastName: "Arasaka"),
        accountNumber: "0000000000",
        routingNumber: "0000000000",
        line1: "Ebunike st., Apt. 32",
        line2: nil,
        city: "Night City",
        country: country,
        region: region,
        regionText: region.name,
        postalCode: "10001"
    )

    static let bankDetails = TangemPayOfframpBankDetails(
        name: "Arasaka Bank",
        line1: "270 Corpo Plaza",
        city: "Night City",
        region: region,
        postalCode: "10017"
    )

    static func state(
        sections: [TransferConfirmationSection] = TransferConfirmationSectionsBuilder.sections(
            personalDetails: personalDetails,
            bankDetails: bankDetails
        )
    ) -> TransferConfirmationContentView.State {
        TransferConfirmationContentView.State(
            balanceText: "$2,130.88",
            amountText: "$500",
            token: TransferInputTokenItem.previewList[0],
            rail: TransferInputRailItem.previewList[0],
            sections: sections,
            footerNote: "You are sending $501 including a ACH fee of $1",
            sendButtonIcon: Assets.tangemIcon,
            isSendEnabled: true
        )
    }
}

#Preview("Personal") {
    TransferConfirmationContentView(state: TransferConfirmationPreview.state(), action: { _ in })
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
}

#Preview("Business") {
    TransferConfirmationContentView(
        state: TransferConfirmationPreview.state(
            sections: TransferConfirmationSectionsBuilder.sections(
                personalDetails: TangemPayOfframpPersonalDetails(
                    name: .business(name: "Arasaka Corporation International"),
                    accountNumber: "0000000000",
                    routingNumber: "0000000000",
                    line1: "Ebunike st., Apt. 32",
                    line2: "Building C",
                    city: "Night City",
                    country: TransferConfirmationPreview.country,
                    region: TransferConfirmationPreview.region,
                    regionText: TransferConfirmationPreview.region.name,
                    postalCode: "10001"
                ),
                bankDetails: TransferConfirmationPreview.bankDetails
            )
        ),
        action: { _ in }
    )
    .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
}
#endif
