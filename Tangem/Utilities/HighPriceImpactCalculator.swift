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

struct HighPriceImpactCalculator {
    private let source: TokenItem
    private let destination: TokenItem

    private let balanceConverter = BalanceConverter()
    private let percentFormatter = PercentFormatter()

    init(source: TokenItem, destination: TokenItem) {
        self.source = source
        self.destination = destination
    }

    /// 10% in the 0..1 range
    private let highPriceImpactWarningLimit: Decimal = 0.1

    func isHighPriceImpact(provider: ExpressProvider, sourceFiatAmount: Decimal, destinationFiatAmount: Decimal) async throws -> Result? {
        let lossesInPercents = (1 - destinationFiatAmount / sourceFiatAmount)

        let isHighPriceImpact = lossesInPercents >= highPriceImpactWarningLimit
        let formatted = percentFormatter.format(-lossesInPercents, option: .express)
        let message = makeMessage(provider: provider, isHighPriceImpact: isHighPriceImpact)

        return Result(
            isHighPriceImpact: isHighPriceImpact,
            lossesInPercents: lossesInPercents,
            lossesInPercentsFormatted: formatted,
            infoMessage: message
        )
    }

    func isHighPriceImpact(provider: ExpressProvider, quote: ExpressQuote) async throws -> Result? {
        guard let sourceCurrencyId = source.currencyId,
              let destinationCurrencyId = destination.currencyId else {
            return nil
        }

        let sourceAmount = quote.fromAmount
        let destinationAmount = quote.expectAmount

        let sourceFiatAmount = try await balanceConverter.convertToFiat(sourceAmount, currencyId: sourceCurrencyId)
        let destinationFiatAmount = try await balanceConverter.convertToFiat(destinationAmount, currencyId: destinationCurrencyId)

        return try await isHighPriceImpact(provider: provider, sourceFiatAmount: sourceFiatAmount, destinationFiatAmount: destinationFiatAmount)
    }

    private func makeMessage(provider: ExpressProvider, isHighPriceImpact: Bool) -> String {
        let slippageFormatted: String? = provider.slippage.map { slippage in
            percentFormatter.format(slippage, option: .init(fractionDigits: 0, clearPrefix: true))
        }

        let cexDescription: String = if let slippageFormatted {
            Localization.swappingAlertCexDescriptionWithSlippage(destination.currencySymbol, slippageFormatted)
        } else {
            Localization.swappingAlertCexDescription(destination.currencySymbol)
        }

        let dexDescription: String = if let slippageFormatted {
            Localization.swappingAlertDexDescriptionWithSlippage(slippageFormatted)
        } else {
            Localization.swappingAlertDexDescription
        }

        switch provider.type {
        case .cex:
            return cexDescription
        case .dex, .dexBridge:
            if isHighPriceImpact {
                return "\(Localization.swappingHighPriceImpactDescription)\n\n\(dexDescription)"
            }

            return dexDescription
        case .onramp, .unknown:
            return Localization.sendErrorUnknown
        }
    }
}

extension HighPriceImpactCalculator {
    struct Result: Hashable {
        let isHighPriceImpact: Bool
        let lossesInPercents: Decimal
        let lossesInPercentsFormatted: String
        let infoMessage: String
    }
}
