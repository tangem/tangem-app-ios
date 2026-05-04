//
//  HighPriceImpactCalculator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress
import TangemLocalization
import TangemMacro

struct HighPriceImpactCalculator {
    private let balanceConverter = BalanceConverter()
    private let percentFormatter = PercentFormatter()

    func calculate(input: Input) async throws -> Result? {
        guard let sourceCurrencyId = input.sourceToken.currencyId,
              let destinationCurrencyId = input.destinationToken.currencyId
        else {
            return nil
        }

        let sourceFiatAmount = try await balanceConverter.convertToFiat(input.sourceAmount, currencyId: sourceCurrencyId)
        let destinationFiatAmount = try await balanceConverter.convertToFiat(input.destinationAmount, currencyId: destinationCurrencyId)

        guard sourceFiatAmount > 0 else {
            return nil
        }

        let sourceAmountUsd = resolveUsdAmount(
            cryptoAmount: input.sourceAmount,
            currencyId: sourceCurrencyId,
            fiatAmount: sourceFiatAmount
        )

        let destinationAmountUsd = resolveUsdAmount(
            cryptoAmount: input.destinationAmount,
            currencyId: destinationCurrencyId,
            fiatAmount: destinationFiatAmount
        )

        let lossesInPercents = (1 - destinationFiatAmount / sourceFiatAmount)
        let formatted = percentFormatter.format(-lossesInPercents, option: .express)

        let level: Level = if isExempt(sourceAmountUsd: sourceAmountUsd) {
            .negligible
        } else {
            determineLevel(lossesInPercents: lossesInPercents, sourceAmountUsd: sourceAmountUsd, destinationAmountUsd: destinationAmountUsd)
        }

        return Result(
            level: level,
            lossesInPercents: lossesInPercents,
            lossesInPercentsFormatted: formatted,
            infoMessage: makeMessage(input: input, level: level)
        )
    }

    /// Returns the USD equivalent of a crypto amount.
    /// If the app currency is already USD, the fiat amount is used directly.
    /// Otherwise falls back to `priceUsd`-based conversion; returns `nil` when unavailable.
    private func resolveUsdAmount(cryptoAmount: Decimal, currencyId: String, fiatAmount: Decimal) -> Decimal? {
        if AppSettings.shared.selectedCurrencyCode == AppConstants.usdCurrencyCode {
            return fiatAmount
        }

        return balanceConverter.convertToUsd(cryptoAmount, currencyId: currencyId)
    }

    private func isExempt(sourceAmountUsd: Decimal?) -> Bool {
        guard let sourceUsd = sourceAmountUsd else {
            return false
        }

        return sourceUsd <= Constants.exemptionUsdThreshold
    }

    private func determineLevel(lossesInPercents: Decimal, sourceAmountUsd: Decimal?, destinationAmountUsd: Decimal?) -> Level {
        if lossesInPercents < Constants.warningLimit {
            // Even below 10%, treat as warning when the absolute USD difference exceeds the threshold
            if let sourceUsd = sourceAmountUsd,
               let destUsd = destinationAmountUsd,
               (sourceUsd - destUsd) >= Constants.highAbsoluteLossUsdThreshold {
                return .warningLoss
            }
            return .negligible
        }

        if lossesInPercents < Constants.blockLimit {
            return .warningLoss
        }

        if let sourceUsd = sourceAmountUsd, sourceUsd > Constants.blockSourceUsdThreshold {
            return .highLossHighAmount
        }

        return .highLossLowAmount
    }

    private func makeMessage(input: Input, level: Level) -> String {
        let slippageFormatted: String? = input.provider.slippage.map { slippage in
            percentFormatter.format(slippage, option: .slippage)
        }

        let destinationSymbol = input.destinationToken.currencySymbol

        let cexDescription: String = if let slippageFormatted {
            Localization.swappingAlertCexDescriptionWithSlippage(destinationSymbol, slippageFormatted)
        } else {
            Localization.swappingAlertCexDescription(destinationSymbol)
        }

        let dexDescription: String = if let slippageFormatted {
            Localization.swappingAlertDexDescriptionWithSlippage(slippageFormatted)
        } else {
            Localization.swappingAlertDexDescription
        }

        switch input.provider.type {
        case .cex:
            return cexDescription
        case .dex, .dexBridge:
            if level == .negligible {
                return dexDescription
            }
            return "\(Localization.swappingHighPriceImpactDescription)\n\n\(dexDescription)"
        case .onramp, .unknown:
            return Localization.sendErrorUnknown
        }
    }
}

// MARK: - Input / Result

extension HighPriceImpactCalculator {
    struct Input {
        let provider: ExpressProvider
        let sourceToken: TokenItem
        let destinationToken: TokenItem
        let sourceAmount: Decimal
        let destinationAmount: Decimal
    }

    struct Result: Hashable {
        let level: Level
        let lossesInPercents: Decimal
        let lossesInPercentsFormatted: String
        let infoMessage: String

        var isBlocked: Bool { level.isHighLossHighAmount }
        var isHighLoss: Bool { level.isHighLossLowAmount || level.isHighLossHighAmount }
    }
}

private extension HighPriceImpactCalculator {
    private enum Constants {
        /// 10% in the 0..1 range
        static let warningLimit = Decimal(stringValue: "0.1")!
        /// 50% in the 0..1 range
        static let blockLimit = Decimal(stringValue: "0.5")!
        /// Block swap button when source amount in USD exceeds this
        static let blockSourceUsdThreshold: Decimal = 5000
        /// Skip warning/blocking when the relevant USD amount is at or below this
        static let exemptionUsdThreshold: Decimal = 25
        /// Show warning when absolute USD loss exceeds this, even if percentage is below warningLimit
        static let highAbsoluteLossUsdThreshold: Decimal = 100_000
    }
}

extension HighPriceImpactCalculator {
    @CaseFlagable
    enum Level: Hashable {
        /// Loss < 10% — no warning needed
        case negligible
        /// 10% ≤ loss ≤ 50% — show warning banner
        case warningLoss
        /// Loss > 50% but source ≤ $5,000 — show warning banner
        case highLossLowAmount
        /// Loss > 50% AND source > $5,000 — show warning banner and block swap
        case highLossHighAmount
    }
}
