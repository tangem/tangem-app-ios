//
//  CommonSwappingFeeFormatter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSwapping

struct CommonSwappingFeeFormatter {
    private let fiatRatesProvider: FiatRatesProviding

    init(fiatRatesProvider: FiatRatesProviding) {
        self.fiatRatesProvider = fiatRatesProvider
    }
}

// MARK: - SwappingFeeFormatter

extension CommonSwappingFeeFormatter: SwappingFeeFormatter {
    func format(fee: Decimal, blockchain: SwappingBlockchain) async throws -> String {
        let fiatFee = try await fiatRatesProvider.getFiat(for: blockchain, amount: fee)

        let feeFormatted = fee.groupedFormatted()
        let fiatFeeFormatted = await fiatFee.currencyFormatted(code: AppSettings.shared.selectedCurrencyCode)

        return "\(feeFormatted) \(blockchain.symbol) (\(fiatFeeFormatted))"
    }

    func syncFormat(fee: Decimal, blockchain: SwappingBlockchain) throws -> String {
        guard let fiatFee = fiatRatesProvider.getSyncFiat(for: blockchain, amount: fee) else {
            throw CommonError.noData
        }

        let feeFormatted = fee.groupedFormatted()
        let fiatFeeFormatted = fiatFee.currencyFormatted(code: AppSettings.shared.selectedCurrencyCode)

        return "\(feeFormatted) \(blockchain.symbol) (\(fiatFeeFormatted))"
    }
}
