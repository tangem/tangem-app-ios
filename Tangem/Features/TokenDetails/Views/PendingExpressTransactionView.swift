//
//  PendingExpressTransactionView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccessibilityIdentifiers
import TangemFoundation
import TangemLocalization
import TangemAssets
import TangemUI

struct PendingExpressTransactionView: View {
    var info: Info

    private let networkIconSize = CGSize(bothDimensions: 18)

    var body: some View {
        Button {
            info.action(info.id)
        } label: {
            content
        }
        .accessibilityIdentifier(TokenAccessibilityIdentifiers.pendingExpressTransaction)
    }

    private var content: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                titleStack

                HStack(spacing: 6) {
                    TokenIcon(
                        tokenIconInfo: info.sourceIconInfo,
                        size: networkIconSize,
                        isWithOverlays: false
                    )

                    SensitiveText(info.sourceAmountText)
                        .style(Fonts.Regular.footnote, color: Colors.Text.primary1)

                    Assets.arrowRightMini.image
                        .renderingMode(.template)
                        .resizable()
                        .frame(size: .init(bothDimensions: 12))
                        .foregroundColor(Colors.Icon.informative)

                    TokenIcon(
                        tokenIconInfo: info.destinationIconInfo,
                        size: networkIconSize,
                        isWithOverlays: false
                    )

                    SensitiveText(info.destinationAmountText)
                        .style(Fonts.Regular.footnote, color: Colors.Text.primary1)
                }
            }

            Spacer(minLength: 6)

            stateIcon

            Assets.chevronRight.image
                .foregroundColor(Colors.Icon.informative)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(Colors.Background.primary)
        .cornerRadiusContinuous(14)
    }

    @ViewBuilder
    private var titleStack: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(info.title)
                .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

            TimelineView(.periodic(from: .now, by: 60)) { context in
                let timeAgo = RelativeDateFormatter.shared.formatTimeAgo(
                    from: info.referenceDate,
                    relativeTo: context.date
                )
                Text("\(info.stateTitle) \(timeAgo)")
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
            }
        }
    }

    @ViewBuilder
    private var stateIcon: some View {
        switch info.state {
        case .inProgress:
            EmptyView()
        case .warning:
            Assets.warningIcon.image
                .frame(size: .init(bothDimensions: 20))
        case .error:
            Assets.redCircleWarning.image
                .frame(size: .init(bothDimensions: 20))
        }
    }
}

extension PendingExpressTransactionView {
    struct Info: Identifiable, Equatable {
        let id: String
        let title: String
        let stateTitle: String
        let referenceDate: Date
        let sourceIconInfo: TokenIconInfo
        let sourceAmountText: String
        let destinationIconInfo: TokenIconInfo
        let destinationAmountText: String
        let state: State
        @IgnoredEquatable private(set) var action: (String) -> Void
    }

    enum State: Equatable {
        case inProgress
        case warning
        case error
    }
}

// MARK: - Previews

#Preview {
    let iconInfoBuilder = TokenIconInfoBuilder()

    ZStack {
        Colors.Background.secondary.edgesIgnoringSafeArea(.all)

        VStack {
            PendingExpressTransactionView(info: .init(
                id: UUID().uuidString,
                title: Localization.expressExchangeBy("ChangeNow"),
                stateTitle: Localization.expressExchangeStatusConfirming,
                referenceDate: Date().addingTimeInterval(-59 * 60),
                sourceIconInfo: iconInfoBuilder.build(from: .blockchain(.init(.polygon(testnet: false), derivationPath: nil)), isCustom: false),
                sourceAmountText: "10 BTC",
                destinationIconInfo: iconInfoBuilder.build(
                    from: .token(.shibaInuMock, .init(.arbitrum(testnet: false), derivationPath: nil)),
                    isCustom: false
                ),
                destinationAmountText: "SHIB",
                state: .inProgress,
                action: { _ in }
            ))

            PendingExpressTransactionView(info: .init(
                id: UUID().uuidString,
                title: Localization.expressExchangeBy("1inch"),
                stateTitle: Localization.expressExchangeStatusVerifying,
                referenceDate: Date().addingTimeInterval(-3 * 3600),
                sourceIconInfo: iconInfoBuilder.build(
                    from: .token(.inverseBTCBlaBlaBlaMock, .init(.ethereum(testnet: false), derivationPath: nil)),
                    isCustom: true
                ),
                sourceAmountText: "10 BTCblabla",
                destinationIconInfo: iconInfoBuilder.build(
                    from: .blockchain(.init(.ethereum(testnet: false), derivationPath: nil)),
                    isCustom: true
                ),
                destinationAmountText: "ETH",
                state: .warning,
                action: { _ in }
            ))

            PendingExpressTransactionView(info: .init(
                id: UUID().uuidString,
                title: Localization.expressExchangeBy("ChangeNow"),
                stateTitle: Localization.expressExchangeStatusFailed,
                referenceDate: Date().addingTimeInterval(-2 * 24 * 3600),
                sourceIconInfo: iconInfoBuilder.build(
                    from: .blockchain(.init(.bitcoin(testnet: false), derivationPath: nil)),
                    isCustom: false
                ),
                sourceAmountText: "10 BTC",
                destinationIconInfo: iconInfoBuilder.build(
                    from: .blockchain(.init(.cardano(extended: false), derivationPath: nil)),
                    isCustom: false
                ),
                destinationAmountText: "ADA",
                state: .error,
                action: { _ in }
            ))
        }
    }
}
