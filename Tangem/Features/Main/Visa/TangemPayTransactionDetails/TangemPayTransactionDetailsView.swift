//
//  TangemPayTransactionDetailsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemUIUtils
import TangemAssets
import TangemLocalization

struct TangemPayTransactionDetailsView: View {
    @ObservedObject var viewModel: TangemPayTransactionDetailsViewModel

    var body: some View {
        if FeatureProvider.isAvailable(.tangemPaySpendRedesign), let displayModel = viewModel.displayModel {
            redesignedBody(displayModel)
        } else {
            legacyBody
        }
    }

    private var legacyBody: some View {
        VStack(spacing: 24) {
            BottomSheetHeaderView(title: viewModel.title, trailing: {
                NavigationBarButton.close(action: viewModel.userDidTapClose)
            })
            .verticalPadding(8)

            mainContainer
        }
        .padding(.top, 8)
        .padding(.horizontal, 16)
        .floatingSheetConfiguration { configuration in
            configuration.sheetBackgroundColor = Colors.Background.primary
            configuration.backgroundInteractionBehavior = .tapToDismiss
        }
    }

    private var mainContainer: some View {
        VStack(spacing: 32) {
            TransactionViewIconView(data: viewModel.iconData, size: .large)

            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    VStack(spacing: 2) {
                        Text(viewModel.name)
                            .style(Fonts.Bold.body, color: Colors.Text.primary1)

                        Text(viewModel.category)
                            .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                    }

                    VStack(spacing: 4) {
                        TransactionViewAmountView(data: viewModel.amount, size: .large)

                        if let localAmount = viewModel.localAmount {
                            Text(localAmount)
                                .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
                        }
                    }
                }

                if let state = viewModel.state {
                    TangemPayTransactionDetailsStateView(state: state)
                }
            }

            bottomContainer
        }
    }

    private var bottomContainer: some View {
        VStack(spacing: 8) {
            bottomInfoView
                .padding(.vertical, 8)

            MainButton(
                title: viewModel.mainButtonAction.title,
                style: .secondary,
                action: viewModel.userDidTapMainButton
            )
            .padding(.vertical, 8)
        }
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var bottomInfoView: some View {
        if let additionalInfo = viewModel.additionalInfo {
            HStack(spacing: 8) {
                additionalInfo.icon
                    .renderingMode(.template)
                    .foregroundStyle(additionalInfo.iconColor)

                Text(additionalInfo.text)
                    .style(Fonts.Regular.footnote, color: additionalInfo.textColor)
            }
            .infinityFrame(axis: .horizontal, alignment: .leading)
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(additionalInfo.backgroundColor)
            )
        }
    }
}

// MARK: - Redesigned

private extension TangemPayTransactionDetailsView {
    func redesignedBody(_ model: TangemPayTransactionDetailsDisplayModel) -> some View {
        VStack(spacing: 0) {
            redesignedHeader(title: model.headerTitle, subtitle: model.headerSubtitle)

            VStack(spacing: 12) {
                redesignedIcon(model.icon)

                VStack(spacing: 8) {
                    Text(model.amount)
                        .style(DesignSystem.Font.displayMediumToken, color: DesignSystem.Color.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    if let amountSubtitle = model.amountSubtitle {
                        Text(amountSubtitle)
                            .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.top, 12)
                .padding(.bottom, 36)

                if let status = model.status {
                    TangemPayTransactionStatusView(model: status)
                }

                redesignedRows(model.rows)
            }
            .padding(.horizontal, 16)
            .padding(.top, 48)
            .padding(.bottom, 8)

            TangemButtonV2(
                label: AttributedString(model.mainButtonAction.title),
                accessibilityLabel: model.mainButtonAction.title,
                action: viewModel.userDidTapMainButton
            )
            .size(.x12)
            .styleType(.default)
            .horizontalLayout(.infinity)
            .padding(16)
        }
        .floatingSheetConfiguration { configuration in
            configuration.sheetBackgroundColor = DesignSystem.Color.bgSecondary
            configuration.backgroundInteractionBehavior = .tapToDismiss
        }
    }

    func redesignedHeader(title: String, subtitle: String) -> some View {
        ZStack {
            VStack(spacing: 4) {
                Text(title)
                    .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)

                Text(subtitle)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
            }
            .multilineTextAlignment(.center)

            HStack(spacing: 0) {
                Spacer(minLength: 0)

                TangemButtonV2(
                    icon: DesignSystem.Icons.Cross.regular20,
                    accessibilityLabel: Localization.commonClose,
                    action: viewModel.userDidTapClose
                )
                .size(.x11)
                .styleType(.material(.glass))
            }
        }
        .padding(.top, 16)
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    func redesignedIcon(_ icon: TangemPayTransactionDetailsDisplayModel.Icon) -> some View {
        switch icon {
        case .merchantLogo(let url):
            IconView(
                url: url,
                size: CGSize(bothDimensions: 80),
                cornerRadius: 80 / 2
            )
        case .withdrawal:
            redesignedGenericIcon(DesignSystem.Icons.ArrowUp.regular24)
        case .deposit:
            redesignedGenericIcon(DesignSystem.Icons.ArrowDown.regular24)
        case .fee:
            redesignedGenericIcon(DesignSystem.Icons.PercentBackward.regular24)
        }
    }

    func redesignedGenericIcon(_ icon: ImageType) -> some View {
        icon.image
            .renderingMode(.template)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 28, height: 28)
            .foregroundStyle(DesignSystem.Color.iconPrimary)
            .frame(width: 80, height: 80)
            .background(DesignSystem.Color.bgOpaquePrimary, in: Circle())
    }

    func redesignedRows(_ rows: [TangemPayTransactionDetailsDisplayModel.Row]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                TangemRow(title: row.title, value: row.value)
                    .showDivider(rows.count == 1 || index < rows.count - 1)
                    .overrideTextColors(.init(value: DesignSystem.Color.textSecondary))
            }
        }
    }
}

extension TangemPayTransactionDetailsView {
    struct AdditionalInfo {
        let text: String
        let textColor: Color
        let icon: Image
        let iconColor: Color
        let backgroundColor: Color
    }
}

extension TangemPayTransactionDetailsView.AdditionalInfo {
    static func declined(reason: String?) -> Self {
        warning(text: TangemPayTransactionDeclineReasonMapper.declinedText(for: reason))
    }

    static let fee: Self = warning(text: Localization.tangemPayTransactionFeeNotificationText)

    static let reversed: Self = .init(
        text: Localization.tangemPayTransactionReversedNotificationText,
        textColor: Colors.Text.tertiary,
        icon: Assets.infoCircle20.image,
        iconColor: Colors.Icon.secondary,
        backgroundColor: Colors.Button.disabled
    )

    private static func warning(text: String) -> Self {
        .init(
            text: text,
            textColor: Colors.Text.warning,
            icon: Assets.infoCircle20.image,
            iconColor: Colors.Icon.warning,
            backgroundColor: Colors.Icon.warning.opacity(0.1)
        )
    }
}
