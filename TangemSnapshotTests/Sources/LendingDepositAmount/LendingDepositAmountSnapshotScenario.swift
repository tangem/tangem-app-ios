//
//  LendingDepositAmountSnapshotScenario.swift
//  TangemSnapshotTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import SwiftUI
import TangemAccounts
import TangemLocalization
import TangemSnapshotTestSupport
import TangemUI
@testable import Tangem

enum LendingDepositAmountSnapshotScenario: String, SnapshotScenario {
    case filled
    case empty
    case exceedsBalance
    case feeLoading
    case feeUnavailable
    case largeText
    case rightToLeft

    var canvases: [SnapshotCanvas] { [.screen(.compact), .screen(.large)] }

    var dynamicTypeSize: DynamicTypeSize {
        self == .largeText ? .xxxLarge : .large
    }

    var layoutDirection: LayoutDirection {
        self == .rightToLeft ? .rightToLeft : .leftToRight
    }

    @MainActor
    var body: some View {
        NavigationStack {
            LendingDepositAmountContentView(field: field, state: state, action: { _ in })
        }
        .environment(\._accessibilityReduceMotion, true)
    }
}

// MARK: - Content

private extension LendingDepositAmountSnapshotScenario {
    static let ether = TokenItem.blockchain(.init(.ethereum(testnet: false), derivationPath: nil))

    var field: AmountInputFieldModel {
        let field = AmountInputFieldModel(tokenItem: Self.ether, fiatItem: FiatItem(iconURL: nil, currencyCode: "USD"))

        switch self {
        case .filled, .feeLoading, .feeUnavailable, .largeText, .rightToLeft:
            field.cryptoTextFieldViewModel.update(value: Decimal(string: "0.5"))
            field.possibleToConvertToFiat = true
            field.alternativeAmount = "$2,130.88"
        case .empty:
            field.possibleToConvertToFiat = true
            field.alternativeAmount = "$0.00"
        case .exceedsBalance:
            field.cryptoTextFieldViewModel.update(value: 3)
            field.possibleToConvertToFiat = true
            field.alternativeAmount = "$12,785.28"
            field.bottomInfoText = .error("Not enough ETH")
        }

        return field
    }

    var state: LendingDepositAmountContentView.StateModel {
        LendingDepositAmountContentView.StateModel(
            header: .account(name: "Main account", icon: .composite(backgroundColor: .blue, nameMode: .letter("M"))),
            tokenIconInfo: TokenIconInfo(
                name: "Ethereum",
                blockchainIconAsset: nil,
                imageURL: nil,
                isCustom: false,
                customTokenColor: nil
            ),
            tokenSymbol: "ETH",
            balance: Localization.commonBalance("2.01 ETH"),
            fee: fee,
            canChangeFeeSpeed: true,
            isDepositEnabled: [.filled, .largeText, .rightToLeft].contains(self)
        )
    }

    var fee: LendingDepositAmountContentView.Fee {
        switch self {
        case .feeLoading: .loading
        case .feeUnavailable: .unavailable
        case .filled, .empty, .exceedsBalance, .largeText, .rightToLeft: .loaded(symbol: "ETH", value: "$1.40")
        }
    }
}
