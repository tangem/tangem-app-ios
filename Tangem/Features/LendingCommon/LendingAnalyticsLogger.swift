//
//  LendingAnalyticsLogger.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

final class LendingAnalyticsLogger {
    typealias Sink = (Analytics.Event, [Analytics.ParameterKey: String]) -> Void

    var feeSelectorScreen: Screen

    private var selectedFeeOption: FeeOption = .market
    private let transactionType: TransactionType
    private let isWithUpgrade: Bool
    private let usdPrice: () -> Decimal?
    private let sink: Sink

    init(
        transactionType: TransactionType,
        isWithUpgrade: Bool,
        usdPrice: @escaping () -> Decimal?,
        sink: @escaping Sink = { Analytics.log(event: $0, params: $1) }
    ) {
        self.transactionType = transactionType
        self.isWithUpgrade = isWithUpgrade
        self.usdPrice = usdPrice
        self.sink = sink
        feeSelectorScreen = transactionType.amountScreen
    }

    var amountScreen: Screen {
        transactionType.amountScreen
    }

    func startFeeSelection(on screen: Screen, from feeOption: FeeOption) {
        feeSelectorScreen = screen
        selectedFeeOption = feeOption
    }
}

// MARK: - Amount screens

extension LendingAnalyticsLogger {
    func logDepositScreenOpened(source: Source, currentApy: Decimal) {
        sink(.ethLendingDepositScreenOpened, [.source: source.rawValue, .currentAPY: Self.percent(currentApy)])
    }

    func logWithdrawScreenOpened(positionBalance: Decimal, availableToWithdraw: Decimal?) {
        var params: [Analytics.ParameterKey: String] = [:]
        params[.positionBucket] = bucket(crypto: positionBalance)
        params[.liquidityCapped] = availableToWithdraw.map { String($0 < positionBalance) }
        sink(.ethLendingWithdrawScreenOpened, params)
    }

    func logCurrencyToggled(to type: SendAmountCalculationType) {
        let displayCurrency = switch type {
        case .crypto: "Crypto"
        case .fiat: "Fiat"
        }

        sink(.ethLendingButtonCurrencyToggle, [.displayCurrency: displayCurrency, .screen: amountScreen.rawValue])
    }

    func logMax() {
        sink(.ethLendingButtonMax, [.screen: amountScreen.rawValue])
    }

    func logPercent(_ percent: Int) {
        sink(.ethLendingButtonPercent, [.percent: String(percent), .screen: amountScreen.rawValue])
    }

    func logNotice(_ notice: Notice) {
        let event: Analytics.Event = switch notice {
        case .insufficientBalance: .ethLendingNoticeInsufficientBalance
        case .insufficientFee: .ethLendingNoticeInsufficientFee
        }

        sink(event, [.screen: amountScreen.rawValue])
    }
}

// MARK: - Confirm and result

extension LendingAnalyticsLogger {
    func logConfirmScreenOpened(amount: Decimal?, currentApy: Decimal?, performanceFee: Decimal?) {
        var params: [Analytics.ParameterKey: String] = [.transactionType: transactionType.rawValue]
        params[.amountBucket] = amount.flatMap(bucket(crypto:))
        params[.currentAPY] = currentApy.map(Self.percent)
        params[.performanceFee] = performanceFee.map(Self.percent)
        sink(.ethLendingConfirmScreenOpened, params)
    }

    func logSent(amount: Decimal?) {
        var signedParams = transactionParams
        signedParams[.amountBucket] = amount.flatMap(bucket(crypto:))
        sink(.ethLendingTransactionSigned, signedParams)
        sink(.ethLendingTransactionSubmitted, transactionParams)
    }

    func logFailure(_ error: TransactionDispatcherResult.Error) {
        switch error {
        case .userCancelled:
            sink(.ethLendingErrorSignCancelled, transactionParams)
        case .sendTxError(_, let sendTxError):
            var params = transactionParams
            params[.errorCode] = String(sendTxError.errorCode)
            sink(.ethLendingErrorTransactionFailed, params)
            sink(.ethLendingNoticeErrorPopup, params)
        case .informationRelevanceServiceError,
             .informationRelevanceServiceFeeWasIncreased,
             .transactionNotFound,
             .feeNotFound,
             .actionNotSupported,
             .loadTransactionInfo,
             .demoAlert:
            break
        }
    }

    func logErrorPopupAction(_ action: ErrorPopupAction) {
        sink(.ethLendingButtonErrorPopup, [.transactionType: transactionType.rawValue, .action: action.rawValue])
    }

    func logSuccessScreenOpened(currentApy: Decimal) {
        var params = transactionParams
        params[.currentAPY] = Self.percent(currentApy)
        sink(.ethLendingSuccessScreenOpened, params)
    }

    func logResultAction(_ destination: Destination) {
        sink(.ethLendingButtonResultAction, [.destination: destination.rawValue])
    }
}

// MARK: - FeeSelectorAnalytics

extension LendingAnalyticsLogger: FeeSelectorAnalytics {
    func logFeeSelected(tokenFee: TokenFee) {
        logFeeSelected(tokenFee.option)
    }

    func logFeeSelected(_ feeOption: FeeOption) {
        guard feeOption != selectedFeeOption else {
            return
        }

        selectedFeeOption = feeOption
        sink(.ethLendingButtonFeeSpeed, [.feeSpeed: feeOption.analyticsValue.rawValue, .screen: feeSelectorScreen.rawValue])
    }

    func logFeeStepOpened() {}
    func logFeeSummaryOpened() {}
    func logFeeTokensOpened(availableTokenFees: [TokenFee]) {}
    func logCustomFeeClicked() {}
}

// MARK: - SendManagementModelAnalyticsLogger

extension LendingAnalyticsLogger: SendManagementModelAnalyticsLogger {
    func logTransactionRejected(error: SendTxError) {}

    func logTransactionSent(
        amount: SendAmount?,
        additionalField: SendDestinationAdditionalField?,
        fee: FeeOption,
        signerType: String,
        currentProviderHost: String,
        tokenFee: TokenFee?
    ) {}
}

// MARK: - Values

extension LendingAnalyticsLogger {
    enum TransactionType: String {
        case deposit = "Deposit"
        case withdraw = "Withdraw"

        var amountScreen: Screen {
            switch self {
            case .deposit: .deposit
            case .withdraw: .withdraw
            }
        }
    }

    enum Source: String {
        case yieldPicker = "Yield Picker"
        case infoScreen = "Info Screen"
    }

    enum Screen: String {
        case deposit = "Deposit"
        case withdraw = "Withdraw"
        case confirm = "Confirm"
    }

    enum Notice: Equatable {
        case insufficientBalance
        case insufficientFee

        static func deposit(amount: Decimal?, fee: Decimal?, balance: Decimal?) -> Notice? {
            guard let balance else {
                return nil
            }

            let amount = amount ?? 0

            if amount > balance {
                return .insufficientBalance
            }

            if let fee, amount + fee > balance {
                return .insufficientFee
            }

            return nil
        }

        static func withdraw(isAmountValid: Bool, isFeeCovered: Bool) -> Notice? {
            guard isFeeCovered else {
                return .insufficientFee
            }

            return isAmountValid ? nil : .insufficientBalance
        }
    }

    enum ErrorPopupAction: String {
        case close = "Close"
        case support = "Support"
    }

    enum Destination: String {
        case token = "Token"
        case yield = "Yield"
    }

    static func usdBucket(_ usd: Decimal) -> String {
        switch usd {
        case ..<50: "<50"
        case ..<250: "50-250"
        case ..<1000: "250-1K"
        case ..<5000: "1K-5K"
        case ..<25000: "5K-25K"
        case ..<100_000: "25K-100K"
        default: ">100K"
        }
    }

    static func percent(_ fraction: Decimal) -> String {
        percentFormatter.string(from: (fraction * 100) as NSDecimalNumber) ?? ""
    }
}

// MARK: - Private

private extension LendingAnalyticsLogger {
    static let percentFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    var transactionParams: [Analytics.ParameterKey: String] {
        [.transactionType: transactionType.rawValue, .withUpgrade: String(isWithUpgrade)]
    }

    func bucket(crypto: Decimal) -> String? {
        usdPrice().map { Self.usdBucket(crypto * $0) }
    }
}
