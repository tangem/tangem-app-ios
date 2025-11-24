//
//  WCApprovalHelpers.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
import BlockchainSdk

enum WCApprovalHelpers {
    static func determineTokenInfo(
        contractAddress: String,
        amount: BigUInt,
        walletModels: [any WalletModel],
        simulationResult: BlockaidChainScanResult?
    ) -> TokenInfo? {
        if let walletInfo = extractFromWallet(contractAddress: contractAddress, walletModels: walletModels) {
            return walletInfo
        }

        if let blockaidInfo = extractFromBlockaid(contractAddress: contractAddress, simulationResult: simulationResult) {
            return blockaidInfo
        }

        if let calculatedInfo = calculateFromBlockaidAmounts(
            contractAddress: contractAddress,
            originalAmount: amount,
            simulationResult: simulationResult
        ) {
            return calculatedInfo
        }

        return nil
    }
}

extension WCApprovalHelpers {
    struct TokenInfo: Equatable {
        let symbol: String
        let decimals: Int
        let source: DataSource

        enum DataSource {
            case wallet
            case blockaidDirect
            case blockaidCalculated
        }

        var reliability: Int {
            switch source {
            case .wallet: return 3
            case .blockaidDirect: return 2
            case .blockaidCalculated: return 1
            }
        }
    }
}

private extension WCApprovalHelpers {
    static func extractFromWallet(
        contractAddress: String,
        walletModels: [any WalletModel]
    ) -> TokenInfo? {
        guard walletModels.isNotEmpty else { return nil }

        for walletModel in walletModels {
            if let token = walletModel.tokenItem.token,
               token.contractAddress.caseInsensitiveCompare(contractAddress) == .orderedSame {
                return TokenInfo(
                    symbol: token.symbol,
                    decimals: token.decimalCount,
                    source: .wallet
                )
            }
        }

        return nil
    }
}

private extension WCApprovalHelpers {
    static func extractFromBlockaid(
        contractAddress: String,
        simulationResult: BlockaidChainScanResult?
    ) -> TokenInfo? {
        guard let result = simulationResult else { return nil }

        if let approvals = result.approvals {
            for approval in approvals {
                if approval.contractAddress?.caseInsensitiveCompare(contractAddress) == .orderedSame {
                    let symbol = approval.symbol ?? approval.name ?? ""
                    let decimals = approval.decimals ?? 18
                    return TokenInfo(
                        symbol: symbol,
                        decimals: decimals,
                        source: .blockaidDirect
                    )
                }
            }
        }

        if let assetsDiff = result.assetsDiff {
            let allAssets = assetsDiff.in + assetsDiff.out

            for asset in allAssets {
                if asset.contractAddress?.caseInsensitiveCompare(contractAddress) == .orderedSame {
                    let symbol = asset.symbol ?? asset.name ?? ""
                    let decimals = asset.decimals ?? 18
                    return TokenInfo(
                        symbol: symbol,
                        decimals: decimals,
                        source: .blockaidDirect
                    )
                }
            }
        }

        return nil
    }
}

private extension WCApprovalHelpers {
    static func calculateFromBlockaidAmounts(
        contractAddress: String,
        originalAmount: BigUInt,
        simulationResult: BlockaidChainScanResult?
    ) -> TokenInfo? {
        guard let result = simulationResult else { return nil }

        var blockaidAmount: Decimal?
        var symbol: String?

        if let approvals = result.approvals {
            for approval in approvals {
                if approval.contractAddress?.caseInsensitiveCompare(contractAddress) == .orderedSame {
                    symbol = approval.symbol ?? approval.name
                    break
                }
            }
        }

        if let assetsDiff = result.assetsDiff {
            let allAssets = assetsDiff.in + assetsDiff.out

            for asset in allAssets {
                if asset.contractAddress?.caseInsensitiveCompare(contractAddress) == .orderedSame {
                    symbol = asset.symbol ?? asset.name
                    blockaidAmount = asset.amount
                    break
                }
            }
        }

        if let blockaidAmount = blockaidAmount, blockaidAmount > 0 {
            let calculatedDecimals = calculateDecimals(
                originalAmount: originalAmount,
                blockaidAmount: blockaidAmount
            )

            if calculatedDecimals >= 0 {
                return TokenInfo(
                    symbol: symbol ?? "",
                    decimals: calculatedDecimals,
                    source: .blockaidCalculated
                )
            }
        }

        return nil
    }

    static func calculateDecimals(originalAmount: BigUInt, blockaidAmount: Decimal) -> Int {
        let originalDecimal = Decimal(string: String(originalAmount)) ?? 0

        let standardDecimals = [0, 6, 8, 9, 12, 18]

        for decimals in standardDecimals {
            let divisor = Decimal(sign: .plus, exponent: decimals, significand: 1)
            let calculated = originalDecimal / divisor

            let difference = abs(calculated - blockaidAmount)
            let tolerance = max(blockaidAmount * 0.01, 0.001)

            if difference <= tolerance {
                return decimals
            }
        }

        return -1
    }
}
