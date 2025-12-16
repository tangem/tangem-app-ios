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
    private let initialCryptoBalance: Decimal?

    private var perTickDeltaInCrypto: Decimal = .zero

    private let balanceConverter = BalanceConverter()

    private let fiatBalanceFormatter = BalanceFormatter()
    private var fiatBalanceFormattingOptions = makeDefaultFormattingOptions()

    private let cryptoBalanceFormatter = BalanceFormatter()
    private var cryptoBalanceFormattingOptions = makeDefaultFormattingOptions()

    var currentCryptoBalancePublisher: AnyPublisher<String, Never> {
        currentCryptoBalanceSubject
            .withWeakCaptureOf(self)
            .compactMap { ticker, currentCryptoBalance in
                guard let currentCryptoBalance else { return nil }
                return ticker.cryptoBalanceFormatter.formatCryptoBalance(
                    currentCryptoBalance,
                    currencyCode: ticker.tokenItem.currencySymbol,
                    formattingOptions: ticker.cryptoBalanceFormattingOptions
                )
            }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    var currentFiatBalancePublisher: AnyPublisher<String, Never> {
        currentCryptoBalanceSubject
            .withWeakCaptureOf(self)
            .compactMap { ticker, currentCryptoBalance in
                guard let currentCryptoBalance,
                      let currentFiatBalance = Self.convertToFiat(
                          balance: currentCryptoBalance,
                          tokenItem: ticker.tokenItem,
                          balanceConverter: ticker.balanceConverter
                      ) else { return nil }

                return ticker.fiatBalanceFormatter.formatFiatBalance(
                    currentFiatBalance,
                    currencyCode: AppSettings.shared.selectedCurrencyCode,
                    formattingOptions: ticker.fiatBalanceFormattingOptions
                )
            }
            .eraseToAnyPublisher()
    }

    private var currentCryptoBalanceSubject = CurrentValueSubject<Decimal?, Never>(nil)

    private var bag: Set<AnyCancellable> = []

    init(tokenItem: TokenItem, initialCryptoBalance: Decimal, apy: Decimal) {
        self.tokenItem = tokenItem
        self.initialCryptoBalance = initialCryptoBalance

        updateCurrentBalance(initialCryptoBalance, apy: apy)

        bind()
    }

    func updateCurrentBalance(_ balance: Decimal, apy: Decimal) {
        perTickDeltaInCrypto = calculatePerTickDeltaInCrypto(balance: balance, apy: apy)

        updateCryptoTickParametersIfNeeded(perTickDeltaInCrypto: perTickDeltaInCrypto)
        updateFiatTickParametersIfNeeded(perTickDeltaInCrypto: perTickDeltaInCrypto)

        // Update only if balance changed to avoid resetting the ticker
        if balance != initialCryptoBalance || currentCryptoBalanceSubject.value == nil {
            currentCryptoBalanceSubject.send(balance)
        }
    }

    private func updateCryptoTickParametersIfNeeded(perTickDeltaInCrypto: Decimal) {
        let minDecimals = BalanceFormattingOptions.defaultCryptoFormattingOptions.minFractionDigits
        let cryptoDecimals = calculateMinVisibleDecimals(
            perTickDelta: perTickDeltaInCrypto,
            minDecimals: minDecimals,
            maxDecimals: tokenItem.decimalCount
        ) ?? minDecimals

        cryptoBalanceFormattingOptions.minFractionDigits = cryptoDecimals
        cryptoBalanceFormattingOptions.maxFractionDigits = cryptoDecimals
        cryptoBalanceFormattingOptions.roundingType = .default(
            roundingMode: .plain,
            scale: cryptoDecimals
        )
    }

    private func updateFiatTickParametersIfNeeded(perTickDeltaInCrypto: Decimal) {
        guard let perTickDeltaInFiat = Self.convertToFiat(
            balance: perTickDeltaInCrypto,
            tokenItem: tokenItem,
            balanceConverter: balanceConverter
        ) else {
            return
        }

        let fiatDecimals = calculateMinVisibleDecimals(
            perTickDelta: perTickDeltaInFiat,
            minDecimals: Constants.minFiatDecimals,
            maxDecimals: Constants.maxFiatDecimals
        ) ?? Constants.defaultDecimals

        fiatBalanceFormattingOptions.minFractionDigits = fiatDecimals
        fiatBalanceFormattingOptions.maxFractionDigits = fiatDecimals
        fiatBalanceFormattingOptions.roundingType = .default(
            roundingMode: .plain,
            scale: fiatDecimals
        )
    }

    private func calculatePerTickDeltaInCrypto(balance: Decimal, apy: Decimal) -> Decimal {
        balance * apy * Constants.tickTimeout / Constants.secondsPerYear
    }

    private func calculateMinVisibleDecimals(
        perTickDelta: Decimal,
        minDecimals: Int,
        maxDecimals: Int
    ) -> Int? {
        guard perTickDelta > 0 else {
            return nil
        }

        guard perTickDelta < 1 else {
            return minDecimals
        }

        let perTickDeltaAsDouble = (perTickDelta as NSDecimalNumber).doubleValue

        let minVisibleDecimals = ceil(-log10(perTickDeltaAsDouble))

        let clamp = Clamp(
            wrappedValue: Int(minVisibleDecimals),
            minValue: minDecimals,
            maxValue: maxDecimals
        )
        return clamp.wrappedValue
    }

    private func bind() {
        Timer.publish(every: Constants.tickTimeout.doubleValue, on: .main, in: .common)
            .autoconnect()
            .withWeakCaptureOf(self)
            .sink { ticker, _ in
                guard let balance = ticker.currentCryptoBalanceSubject.value else { return }

                ticker.currentCryptoBalanceSubject.send(balance + ticker.perTickDeltaInCrypto)
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

    private static func makeDefaultFormattingOptions() -> BalanceFormattingOptions {
        BalanceFormattingOptions(
            minFractionDigits: Constants.defaultDecimals,
            maxFractionDigits: Constants.defaultDecimals,
            formatEpsilonAsLowestRepresentableValue: true,
            roundingType: .default(roundingMode: .plain, scale: Constants.defaultDecimals)
        )
    }
}

extension YieldBalanceTicker {
    enum Constants {
        static let tickTimeout = Decimal(stringValue: "0.8")!
        static let secondsPerYear: Decimal = 31536000 // 365 * 24 * 60 * 60

        static let defaultDecimals = 2
        static let minFiatDecimals = 3
        static let maxFiatDecimals = 12
    }
}
