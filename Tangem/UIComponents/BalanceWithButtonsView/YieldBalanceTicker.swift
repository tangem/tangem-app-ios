//
//  YieldBalanceTicker.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import Combine

final class YieldBalanceTicker {
    private let tokenItem: TokenItem
    private let initialFiatBalance: Decimal?

    private var perTickDelta: Decimal = .zero

    private let balanceConverter = BalanceConverter()

    private let balanceFormatter = BalanceFormatter()
    private var balanceFormattingOptions = BalanceFormattingOptions(
        minFractionDigits: Constants.defaultDecimals,
        maxFractionDigits: Constants.defaultDecimals,
        formatEpsilonAsLowestRepresentableValue: true,
        roundingType: .default(roundingMode: .plain, scale: Constants.defaultDecimals)
    )

    var currentBalancePublisher: AnyPublisher<String, Never> {
        currentBalanceSubject
            .withWeakCaptureOf(self)
            .compactMap { ticker, currentBalance in
                guard let currentBalance else { return nil }
                return ticker.balanceFormatter.formatFiatBalance(
                    currentBalance,
                    currencyCode: AppSettings.shared.selectedCurrencyCode,
                    formattingOptions: ticker.balanceFormattingOptions
                )
            }
            .eraseToAnyPublisher()
    }

    private var currentBalanceSubject = CurrentValueSubject<Decimal?, Never>(nil)

    private var bag: Set<AnyCancellable> = []

    init(tokenItem: TokenItem, initialBalance: Decimal, apy: Decimal) {
        self.tokenItem = tokenItem
        initialFiatBalance = Self.convertToFiat(
            balance: initialBalance,
            tokenItem: tokenItem,
            balanceConverter: balanceConverter
        )

        updateCurrentBalance(initialBalance, apy: apy)

        bind()
    }

    func updateCurrentBalance(_ balance: Decimal, apy: Decimal) {
        guard let fiatBalance = Self.convertToFiat(
            balance: balance,
            tokenItem: tokenItem,
            balanceConverter: balanceConverter
        ) else { return }

        updateTickParametersIfNeeded(balance: fiatBalance, apy: apy)

        // Update only if balance changed to avoid resetting the ticker
        if fiatBalance != initialFiatBalance || currentBalanceSubject.value == nil {
            currentBalanceSubject.send(fiatBalance)
        }
    }

    private func updateTickParametersIfNeeded(balance: Decimal, apy: Decimal) {
        let delta = calculatePerTickDelta(balance: balance, apy: apy)
        let decimals = calculateMinVisibleDecimals(perTickDelta: delta)

        perTickDelta = delta

        balanceFormattingOptions.minFractionDigits = decimals
        balanceFormattingOptions.maxFractionDigits = decimals
        balanceFormattingOptions.roundingType = .default(
            roundingMode: .plain,
            scale: decimals
        )
    }

    private func calculatePerTickDelta(balance: Decimal, apy: Decimal) -> Decimal {
        balance * apy * Constants.tickTimeout / Constants.secondsPerYear
    }

    private func calculateMinVisibleDecimals(perTickDelta: Decimal) -> Int {
        guard perTickDelta > 0 else {
            return Constants.defaultDecimals
        }

        guard perTickDelta < 1 else {
            return Constants.minDecimals
        }

        let perTickAsDouble = (perTickDelta as NSDecimalNumber).doubleValue

        let raw = ceil(-log(perTickAsDouble) / log(10))

        let clamp = Clamp(
            wrappedValue: Int(raw) + Constants.additionalDigitsCount,
            minValue: Constants.minDecimals,
            maxValue: Constants.maxDecimals
        )
        return clamp.wrappedValue
    }

    private func bind() {
        Timer.publish(every: Constants.tickTimeout.doubleValue, on: .main, in: .common)
            .autoconnect()
            .withWeakCaptureOf(self)
            .sink { ticker, _ in
                guard let balance = ticker.currentBalanceSubject.value else { return }

                ticker.currentBalanceSubject.send(balance + ticker.perTickDelta)
            }
            .store(in: &bag)
    }

    private static func convertToFiat(
        balance: Decimal,
        tokenItem: TokenItem,
        balanceConverter: BalanceConverter
    ) -> Decimal? {
        guard let currencyId = tokenItem.currencyId else { return nil }
        return balanceConverter.convertToFiat(balance, currencyId: currencyId)
    }
}

extension YieldBalanceTicker {
    enum Constants {
        static let tickTimeout = Decimal(stringValue: "0.3")!
        static let secondsPerYear: Decimal = 31536000 // 365 * 24 * 60 * 60
        static let defaultDecimals = 2
        static let minDecimals = 3
        static let maxDecimals = 12
        static let additionalDigitsCount = 1
    }
}
