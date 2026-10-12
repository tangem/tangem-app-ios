//
//  TangemPayTransactionDetailsContentView.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemUIUtils
import TangemAssets
import TangemLocalization
import TangemAccessibilityIdentifiers

struct TangemPayTransactionDetailsContentView: View {
    let state: TangemPayTransactionDetailsDisplayModel
    let action: (Action) -> Void

    var body: some View {
        VStack(spacing: 0) {
            header(title: state.headerTitle, subtitle: state.headerSubtitle)

            ScrollView {
                scrollableContent
            }
            .scrollBounceBehavior(.basedOnSize)

            TangemUI.Button(
                label: AttributedString(state.mainButtonAction.title),
                accessibilityLabel: state.mainButtonAction.title,
                action: { action(.mainButton) }
            )
            .size(.x12)
            .styleType(.default)
            .horizontalLayout(.infinity)
            .padding(16)
            .accessibilityIdentifier(TangemPayAccessibilityIdentifiers.transactionDetailsMainButton)
        }
    }
}

// MARK: - Action

extension TangemPayTransactionDetailsContentView {
    enum Action {
        case close
        case mainButton
        case retryCardLoad
        case retryCashbackLoad
    }
}

// MARK: - Content

private extension TangemPayTransactionDetailsContentView {
    var scrollableContent: some View {
        VStack(spacing: 12) {
            iconView(state.icon)
                .accessibilityIdentifier(TangemPayAccessibilityIdentifiers.transactionDetailsIcon)

            VStack(spacing: 8) {
                SensitiveText(state.amount)
                    .style(DesignSystem.Font.displayMediumToken, color: DesignSystem.Color.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier(TangemPayAccessibilityIdentifiers.transactionDetailsAmount)

                if let amountSubtitle = state.amountSubtitle {
                    Text(amountSubtitle)
                        .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier(TangemPayAccessibilityIdentifiers.transactionDetailsAmountSubtitle)
                }
            }
            .padding(.top, 12)
            .padding(.bottom, 36)

            if let status = state.status {
                TangemPayTransactionStatusView(model: status)
            }

            VStack(spacing: 0) {
                cardRowView
                cashbackRowView
                rowsView(state.rows)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 48)
        .padding(.bottom, 8)
    }

    func header(title: String, subtitle: String) -> some View {
        ZStack {
            VStack(spacing: 4) {
                Text(title)
                    .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                    .accessibilityIdentifier(TangemPayAccessibilityIdentifiers.transactionDetailsTitle)

                Text(subtitle)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                    .accessibilityIdentifier(TangemPayAccessibilityIdentifiers.transactionDetailsDate)
            }
            .multilineTextAlignment(.center)

            HStack(spacing: 0) {
                Spacer(minLength: 0)

                TangemUI.Button(
                    icon: DesignSystem.Icons.Cross.regular20,
                    accessibilityLabel: Localization.commonClose,
                    action: { action(.close) }
                )
                .size(.x11)
                .styleType(.material(.glass))
            }
        }
        .padding(.top, 16)
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    func iconView(_ icon: TangemPayTransactionDetailsDisplayModel.Icon) -> some View {
        switch icon {
        case .merchantLogo(let url?):
            IconView(
                url: url,
                size: CGSize(bothDimensions: 80),
                cornerRadius: 80 / 2
            )
        case .merchantLogo(nil):
            genericIconView(Assets.Visa.otherTransaction)
        case .withdrawal:
            genericIconView(DesignSystem.Icons.ArrowUp.regular24)
        case .deposit:
            genericIconView(DesignSystem.Icons.ArrowDown.regular24)
        case .fee, .cashback:
            genericIconView(DesignSystem.Icons.PercentBackward.regular24)
        }
    }

    func genericIconView(_ icon: ImageType) -> some View {
        icon.image
            .renderingMode(.template)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 28, height: 28)
            .foregroundStyle(DesignSystem.Color.iconSecondary)
            .frame(width: 80, height: 80)
            .background(DesignSystem.Color.bgTransparentPrimary, in: Circle())
    }

    func rowsView(_ rows: [TangemPayTransactionDetailsDisplayModel.Row]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                Row(title: row.title, value: row.value)
                    .showDivider(rows.count == 1 || index < rows.count - 1)
                    .overrideTextColors(.init(value: DesignSystem.Color.textSecondary))
                    .accessibilityIdentifier(row.accessibilityIdentifier)
            }
        }
    }

    @ViewBuilder
    var cardRowView: some View {
        if let cardRow = state.cardRow {
            switch cardRow {
            case .loading:
                Row(title: Localization.tangempayCommonCard)
                    .verticalAlignment(.top)
                    .valueAccessory {
                        shimmerLine(width: 157, token: DesignSystem.Font.bodyMediumToken)
                    }
                    .subvalueAccessory {
                        shimmerLine(width: 84, token: DesignSystem.Font.captionMediumToken)
                    }
                    .showDivider()
                    .accessibilityIdentifier(TangemPayAccessibilityIdentifiers.transactionDetailsCardRow)
            case .loaded(let cardNumberEnd, let cardName):
                Row(
                    title: Localization.tangempayCommonCard,
                    value: "*" + cardNumberEnd,
                    subvalue: cardName
                )
                .verticalAlignment(.top)
                .overrideTextColors(.init(value: DesignSystem.Color.textSecondary))
                .showDivider()
                .accessibilityIdentifier(TangemPayAccessibilityIdentifiers.transactionDetailsCardRow)
            case .failed:
                Row(title: Localization.tangempayCommonCard)
                    .valueAccessory {
                        errorLoadingAccessory(action: { action(.retryCardLoad) })
                            .accessibilityIdentifier(TangemPayAccessibilityIdentifiers.transactionDetailsCardRowRetryButton)
                    }
                    .showDivider()
                    .accessibilityIdentifier(TangemPayAccessibilityIdentifiers.transactionDetailsCardRow)
            }
        }
    }

    @ViewBuilder
    var cashbackRowView: some View {
        if let cashbackRow = state.cashbackRow {
            switch cashbackRow {
            case .loading, .awaitingCalculation:
                Row(title: Localization.tangempayCashbackTitle)
                    .valueAccessory {
                        shimmerLine(width: 157, token: DesignSystem.Font.bodyMediumToken)
                    }
                    .showDivider()
            case .loaded(let row):
                cashbackLoadedRow(row)
            case .failed:
                Row(title: Localization.tangempayCashbackTitle)
                    .valueAccessory {
                        errorLoadingAccessory(action: { action(.retryCashbackLoad) })
                    }
                    .showDivider()
            }
        }
    }

    @ViewBuilder
    func cashbackLoadedRow(_ row: TangemPayTransactionDetailsDisplayModel.CashbackRow) -> some View {
        let verticalAlignment: RowVerticalAlignment = row.subvalue == nil ? .center : .top

        switch row.value {
        case .amount(let amount):
            Row(title: Localization.tangempayCashbackTitle, subvalue: row.subvalue)
                .verticalAlignment(verticalAlignment)
                .valueAccessory {
                    SensitiveText(amount)
                        .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textSecondary)
                }
                .showDivider()
        case .text(let text):
            Row(title: Localization.tangempayCashbackTitle, value: text, subvalue: row.subvalue)
                .verticalAlignment(verticalAlignment)
                .overrideTextColors(.init(value: DesignSystem.Color.textSecondary))
                .showDivider()
        }
    }

    func errorLoadingAccessory(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(Localization.tangempayCommonErrorLoading)
                    .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textStatusError)

                DesignSystem.Icons.ArrowRefresh.regular20.image
                    .renderingMode(.template)
                    .foregroundStyle(DesignSystem.Color.iconStatusError)
            }
        }
        .buttonStyle(.plain)
    }

    func shimmerLine(width: CGFloat, token: TangemTypographyToken) -> some View {
        Text(" ")
            .style(token, color: .clear)
            .frame(width: width)
            .overlay {
                SkeletonView()
                    .clipShape(Capsule())
                    .padding(.vertical, 2)
            }
    }
}

// MARK: - Previews

#Preview("Cashback") {
    TangemPayTransactionDetailsContentView(
        state: .init(
            headerTitle: Localization.tangempayCashbackTitle,
            headerSubtitle: "Jun 20 2026, 21:24",
            icon: .cashback,
            amount: "+$19.00",
            amountSubtitle: nil,
            status: nil,
            rows: [.init(title: Localization.tangemPayTransactionDetailsCategory, value: Localization.commonTransfer)],
            mainButtonAction: .info
        ),
        action: { _ in }
    )
    .frame(height: 470)
    .background(DesignSystem.Color.bgSecondary)
}

#Preview("Deposit") {
    TangemPayTransactionDetailsContentView(
        state: .init(
            headerTitle: Localization.tangemPayDeposit,
            headerSubtitle: "Jun 20 2026, 21:24",
            icon: .deposit,
            amount: "+$1.00",
            amountSubtitle: nil,
            status: nil,
            rows: [.init(title: Localization.tangemPayTransactionDetailsCategory, value: Localization.commonTransfer)],
            mainButtonAction: .info
        ),
        action: { _ in }
    )
    .frame(height: 470)
    .background(DesignSystem.Color.bgSecondary)
}

#Preview("Withdrawal") {
    TangemPayTransactionDetailsContentView(
        state: .init(
            headerTitle: Localization.tangemPayWithdrawal,
            headerSubtitle: "Jun 20 2026, 21:24",
            icon: .withdrawal,
            amount: "-$1.00",
            amountSubtitle: nil,
            status: nil,
            rows: [.init(title: Localization.tangemPayTransactionDetailsCategory, value: Localization.commonTransfer)],
            mainButtonAction: .info
        ),
        action: { _ in }
    )
    .frame(height: 470)
    .background(DesignSystem.Color.bgSecondary)
}
