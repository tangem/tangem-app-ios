//
//  LendingWithdrawSnapshotScenario.swift
//  TangemSnapshotTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemSnapshotTestSupport
import TangemUI
@testable import Tangem

enum LendingWithdrawSnapshotScenario: String, SnapshotScenario {
    case amount
    case amountFeeNotCovered
    case amountFeeUnavailable
    case amountLargeText
    case amountRightToLeft
    case confirm
    case confirmLargeText
    case confirmRightToLeft

    var canvases: [SnapshotCanvas] { [.screen(.compact), .screen(.large)] }

    var dynamicTypeSize: DynamicTypeSize {
        [.amountLargeText, .confirmLargeText].contains(self) ? .xxxLarge : .large
    }

    var layoutDirection: LayoutDirection {
        [.amountRightToLeft, .confirmRightToLeft].contains(self) ? .rightToLeft : .leftToRight
    }

    @MainActor
    var body: some View {
        NavigationStack {
            switch self {
            case .amount, .amountFeeNotCovered, .amountFeeUnavailable, .amountLargeText, .amountRightToLeft:
                LendingWithdrawAmountContentView(field: field, state: amountState, action: { _ in })
            case .confirm, .confirmLargeText, .confirmRightToLeft:
                LendingWithdrawConfirmContentView(state: confirmState, action: { _ in })
            }
        }
        .environment(\._accessibilityReduceMotion, true)
    }
}

// MARK: - Content

private extension LendingWithdrawSnapshotScenario {
    static let ether = TokenItem.blockchain(.init(.ethereum(testnet: false), derivationPath: nil))

    static let iconInfo = TokenIconInfo(
        name: "Ethereum",
        blockchainIconAsset: nil,
        imageURL: nil,
        isCustom: false,
        customTokenColor: nil
    )

    var field: AmountInputFieldModel {
        let field = AmountInputFieldModel(tokenItem: Self.ether, fiatItem: FiatItem(iconURL: nil, currencyCode: "USD"))
        field.cryptoTextFieldViewModel.update(value: Decimal(string: "0.5"))
        field.possibleToConvertToFiat = true
        field.alternativeAmount = "$2,130.88"
        if self == .amountFeeNotCovered {
            field.bottomInfoText = .error(LendingWithdrawText.notEnough("ETH"))
        }
        return field
    }

    var amountState: LendingAmountContentView.StateModel {
        LendingAmountContentView.StateModel(
            header: nil,
            source: LendingAmountContentView.Source(
                tokenIconInfo: Self.iconInfo,
                title: LendingWithdrawText.source,
                subtitle: LendingWithdrawText.availableBalance("2.01 ETH")
            ),
            fee: self == .amountFeeUnavailable ? .unavailable : .loaded(symbol: "ETH", value: "$1.40"),
            canChangeFeeSpeed: true,
            notice: LendingWithdrawText.notice,
            submitTitle: LendingWithdrawText.withdraw,
            isSubmitEnabled: [.amount, .amountLargeText, .amountRightToLeft].contains(self)
        )
    }

    var confirmState: LendingWithdrawConfirmContentView.StateModel {
        LendingWithdrawConfirmContentView.StateModel(
            tokenIconInfo: Self.iconInfo,
            fiatAmount: "$800",
            cryptoAmount: "0.5 ETH",
            fee: .loaded(symbol: "ETH", value: "$1.40"),
            canChangeFeeSpeed: true,
            signingActionButtonType: .requiredNFCInteraction,
            isWithdrawEnabled: true,
            isWithdrawing: false
        )
    }
}
