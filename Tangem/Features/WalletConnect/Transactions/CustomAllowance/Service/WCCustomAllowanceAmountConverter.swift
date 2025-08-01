//
//  WCCustomAllowanceAmountConverter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
import TangemLocalization

struct WCCustomAllowanceAmountConverter {
    private let tokenInfo: WCApprovalHelpers.TokenInfo

    init(tokenInfo: WCApprovalHelpers.TokenInfo) {
        self.tokenInfo = tokenInfo
    }

    func parseInputToBigUInt(_ input: String) -> BigUInt? {
        guard !input.isEmpty else {
            return nil
        }

        guard let decimal = Decimal(string: input) else {
            return nil
        }

        return convertDecimalToBigUInt(decimal)
    }

    func formatBigUIntForInput(_ bigUInt: BigUInt) -> String? {
        guard let decimal = convertBigUIntToDecimal(bigUInt) else {
            return nil
        }

        return formatDecimalForInput(decimal)
    }

    func formatBigUIntForDisplay(_ bigUInt: BigUInt) -> String {
        if bigUInt == BigUInt.maxUInt256 {
            return Localization.wcCommonUnlimited
        }

        guard let decimal = convertBigUIntToDecimal(bigUInt) else {
            return formatBigUIntFallback(bigUInt)
        }

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = min(tokenInfo.decimals, 8)
        formatter.minimumFractionDigits = 0

        let formattedValue = formatter.string(from: decimal as NSDecimalNumber) ?? formatBigUIntFallback(bigUInt)

        return "\(formattedValue) \(tokenInfo.symbol)"
    }

    private func convertDecimalToBigUInt(_ decimal: Decimal) -> BigUInt? {
        let multiplier = Decimal(sign: .plus, exponent: tokenInfo.decimals, significand: 1)
        let weiDecimal = decimal * multiplier

        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        formatter.usesGroupingSeparator = false

        guard let weiString = formatter.string(from: weiDecimal as NSDecimalNumber) else {
            return nil
        }

        return BigUInt(weiString)
    }

    private func convertBigUIntToDecimal(_ bigUInt: BigUInt) -> Decimal? {
        let bigUIntString = String(bigUInt)
        guard let decimal = Decimal(string: bigUIntString) else {
            return nil
        }

        let divisor = Decimal(sign: .plus, exponent: tokenInfo.decimals, significand: 1)
        return decimal / divisor
    }

    private func formatDecimalForInput(_ decimal: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = min(tokenInfo.decimals, 8)
        formatter.minimumFractionDigits = 0
        formatter.usesGroupingSeparator = false

        return formatter.string(from: decimal as NSDecimalNumber) ?? "0"
    }

    private func formatBigUIntFallback(_ bigUInt: BigUInt) -> String {
        let amountString = String(bigUInt)
        if amountString.count > 12 {
            let prefix = String(amountString.prefix(6))
            return "\(prefix)..."
        }
        return amountString
    }
}
