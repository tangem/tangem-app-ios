//
//  TangemPayVirtualAccountDetailsContentView.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization
import TangemUIUtils

struct TangemPayVirtualAccountDetailsContentView: View {
    let state: State
    let action: (Action) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Constants.spacing) {
                credentialsSection

                feesSection

                limitationsSection
            }
            .padding(.top, Constants.topPadding)
            .padding(.horizontal, Constants.horizontalPadding)
            .padding(.bottom, Constants.bottomPadding)
        }
        .scrollIndicators(.hidden)
        .background { DesignSystem.Color.bgPrimary.ignoresSafeArea() }
        .offrampBottomBar { shareButton }
        .animation(.contentFrameUpdate, value: state.fees)
    }
}

// MARK: - Credentials

private extension TangemPayVirtualAccountDetailsContentView {
    var credentialsSection: some View {
        card {
            ForEach(Array(state.rows.enumerated()), id: \.element.id) { index, row in
                credentialRow(row)

                if index < state.rows.count - 1 {
                    separator
                }
            }
        }
    }

    func credentialRow(_ row: Row) -> some View {
        SwiftUI.Button(action: { action(.copy(row)) }) {
            HStack(alignment: .center, spacing: Constants.rowContentSpacing) {
                VStack(alignment: .leading, spacing: Constants.credentialTitleSpacing) {
                    Text(verbatim: row.title)
                        .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)

                    Text(verbatim: row.value)
                        .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                DesignSystem.Icons.Copy.regular20.image
                    .renderingMode(.template)
                    .foregroundStyle(DesignSystem.Color.iconPrimary)
            }
            .padding(.vertical, Constants.credentialRowVerticalPadding)
        }
    }
}

// MARK: - Fees

private extension TangemPayVirtualAccountDetailsContentView {
    @ViewBuilder
    var feesSection: some View {
        if state.fees != .empty {
            VStack(alignment: .leading, spacing: Constants.sectionSpacing) {
                sectionHeader(Localization.tangempayBankTransferDetailsFeeHeader)

                feesCard

                if state.fees != .failed {
                    sectionFooter(Localization.tangempayBankTransferSwiftWarning)
                }
            }
        }
    }

    @ViewBuilder
    var feesCard: some View {
        switch state.fees {
        case .loading:
            card {
                feePlaceholderRow

                separator

                feePlaceholderRow
            }
        case .loaded(let fees):
            card {
                ForEach(Array(fees.enumerated()), id: \.element.id) { index, fee in
                    keyValueRow(title: fee.title, value: fee.value)

                    if index < fees.count - 1 {
                        separator
                    }
                }
            }
        case .empty:
            EmptyView()
        case .failed:
            feeErrorBanner
        }
    }

    var feePlaceholderRow: some View {
        HStack(spacing: Constants.rowContentSpacing) {
            Shimmer()
                .variant(.text(style: .body, alignment: .leading))

            Shimmer()
                .variant(.text(style: .body, alignment: .trailing))
        }
    }

    var feeErrorBanner: some View {
        MessageBanner(
            title: Localization.tangempayBankTransferFeeErrorTitle,
            description: Localization.tangempayBankTransferFeeErrorSubtitle
        )
        .variant(.error)
        .glowRing(.error)
        .slotEnd {
            DesignSystem.Icons.ArrowRefresh.regular20.image
                .renderingMode(.template)
                .foregroundStyle(DesignSystem.Color.iconPrimary)
        }
        .onTap { action(.reloadFees) }
    }
}

// MARK: - Limitations

private extension TangemPayVirtualAccountDetailsContentView {
    var limitationsSection: some View {
        VStack(alignment: .leading, spacing: Constants.sectionSpacing) {
            sectionHeader(Localization.tangempayBankTransferDetailsLimitations)

            card {
                keyValueRow(
                    title: Localization.tangempayBankTransferDetailsDailyDeposits,
                    value: state.dailyDepositLimit
                )

                separator

                Text(Localization.tangempayBankTransferDetailsDailyDepositsHint(state.dailyDepositLimit))
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                    .multilineTextAlignment(.leading)
            }
        }
    }
}

// MARK: - Share

private extension TangemPayVirtualAccountDetailsContentView {
    var shareButton: some View {
        TangemUI.Button(
            label: AttributedString(Localization.commonShare),
            accessibilityLabel: Localization.commonShare,
            action: { action(.share) }
        )
        .styleType(.primary)
        .size(.x14)
        .horizontalLayout(.infinity)
    }
}

// MARK: - Building blocks

private extension TangemPayVirtualAccountDetailsContentView {
    func card(@ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: Constants.cardSpacing) {
            content()
        }
        .padding(.vertical, Constants.cardVerticalPadding)
        .padding(.horizontal, Constants.cardHorizontalPadding)
        .background(DesignSystem.Color.bgSecondary)
        .cornerRadiusContinuous(Constants.cardCornerRadius)
    }

    var separator: some View {
        Separator(height: .minimal, color: DesignSystem.Color.borderSecondary)
    }

    func keyValueRow(title: String, value: String?) -> some View {
        HStack(spacing: Constants.rowContentSpacing) {
            Text(verbatim: title)
                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)

            Spacer(minLength: 0)

            if let value {
                Text(verbatim: value)
                    .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textSecondary)
            }
        }
        .overlay(alignment: .trailing) {
            if value == nil {
                Shimmer()
                    .variant(.text(style: .body, alignment: .trailing))
            }
        }
    }

    func sectionHeader(_ text: String) -> some View {
        Text(text)
            .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
            .padding(.horizontal, Constants.sectionTextHorizontalPadding)
    }

    func sectionFooter(_ text: String) -> some View {
        Text(text)
            .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
            .multilineTextAlignment(.leading)
            .padding(.horizontal, Constants.sectionTextHorizontalPadding)
    }
}

// MARK: - Constants

private extension TangemPayVirtualAccountDetailsContentView {
    enum Constants {
        static let spacing: CGFloat = 26
        static let topPadding: CGFloat = 12
        static let horizontalPadding: CGFloat = 16
        static let bottomPadding: CGFloat = 16
        static let cardVerticalPadding: CGFloat = 12
        static let cardHorizontalPadding: CGFloat = 16
        static let cardCornerRadius: CGFloat = 24
        static let cardSpacing: CGFloat = 12
        static let sectionSpacing: CGFloat = 8
        static let rowContentSpacing: CGFloat = 12
        static let credentialTitleSpacing: CGFloat = 4
        static let credentialRowVerticalPadding: CGFloat = 4
        static let sectionTextHorizontalPadding: CGFloat = 16
    }
}

// MARK: - Animations

private extension Animation {
    static let contentFrameUpdate = Animation.curve(.easeInOutRefined, duration: 0.5)
}

// MARK: - State

extension TangemPayVirtualAccountDetailsContentView {
    struct State {
        let rows: [Row]
        var fees: Fees
        let dailyDepositLimit: String
    }

    struct Row: Identifiable {
        var id: String { key }
        let key: String
        let title: String
        let value: String
    }

    enum Fees: Hashable {
        case loading
        case loaded([TangemPayVirtualAccountFee])
        case empty
        case failed
    }
}

// MARK: - Action

extension TangemPayVirtualAccountDetailsContentView {
    enum Action {
        case copy(Row)
        case reloadFees
        case share
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Loading") {
    TangemPayVirtualAccountDetailsContentView(
        state: .preview(fees: .loading),
        action: { _ in }
    )
}

#Preview("Loaded") {
    TangemPayVirtualAccountDetailsContentView(
        state: .preview(fees: .loaded(.previews)),
        action: { _ in }
    )
}

#Preview("Empty") {
    TangemPayVirtualAccountDetailsContentView(
        state: .preview(fees: .empty),
        action: { _ in }
    )
}

#Preview("Failed") {
    TangemPayVirtualAccountDetailsContentView(
        state: .preview(fees: .failed),
        action: { _ in }
    )
}

private extension TangemPayVirtualAccountDetailsContentView.State {
    static func preview(fees: TangemPayVirtualAccountDetailsContentView.Fees) -> Self {
        Self(
            rows: [
                .init(key: "account_number", title: Localization.virtualAccountRequisitesAccountNumber, value: "0000000000000"),
                .init(key: "routing_number", title: Localization.virtualAccountRequisitesRoutingNumber, value: "000000000"),
                .init(key: "beneficiary_name", title: Localization.virtualAccountRequisitesBeneficiaryName, value: "RAIN PAYMENTS INC"),
                .init(key: "beneficiary_address", title: Localization.virtualAccountRequisitesBeneficiaryAddress, value: "123 Finance St, New York, NY 10001, US"),
                .init(key: "bank_name", title: Localization.virtualAccountRequisitesBankName, value: "SSB Bank"),
                .init(key: "bank_address", title: Localization.virtualAccountRequisitesBankAddress, value: "8700 Perry Highway, Pittsburgh, PA 15237, US"),
            ],
            fees: fees,
            dailyDepositLimit: "$10,000"
        )
    }
}
#endif
