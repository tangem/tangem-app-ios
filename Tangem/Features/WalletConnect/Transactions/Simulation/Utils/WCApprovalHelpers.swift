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

/// Strict algorithm for determining token data for approval transactions
enum WCApprovalHelpers {
    // MARK: - Main Algorithm

    /// Determines token data using strict priority algorithm
    static func determineTokenInfo(
        contractAddress: String,
        amount: BigUInt,
        userWalletModel: UserWalletModel?,
        simulationResult: BlockaidChainScanResult?
    ) -> TokenInfo? {
        // 1. PRIORITY: Data from user wallet (most accurate)
        if let walletInfo = extractFromWallet(contractAddress: contractAddress, userWalletModel: userWalletModel) {
            return walletInfo
        }

        // 2. PRIORITY: Data from Blockaid results
        if let blockaidInfo = extractFromBlockaid(contractAddress: contractAddress, simulationResult: simulationResult) {
            return blockaidInfo
        }

        // 3. PRIORITY: Mathematical calculation of decimals from Blockaid amounts
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

// MARK: - Data Model

extension WCApprovalHelpers {
    struct TokenInfo: Equatable {
        let symbol: String
        let decimals: Int
        let source: DataSource

        enum DataSource {
            case wallet // From user wallet models
            case blockaidDirect // Directly from Blockaid results
            case blockaidCalculated // Calculated from Blockaid amounts
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

// MARK: - Wallet Extraction

private extension WCApprovalHelpers {
    static func extractFromWallet(
        contractAddress: String,
        userWalletModel: UserWalletModel?
    ) -> TokenInfo? {
        guard let userWalletModel = userWalletModel else { return nil }

        // Search for token in wallet models
        let allWalletModels = userWalletModel.walletModelsManager.walletModels

        for model in allWalletModels {
            if let token = model.tokenItem.token,
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

// MARK: - Blockaid Extraction

private extension WCApprovalHelpers {
    static func extractFromBlockaid(
        contractAddress: String,
        simulationResult: BlockaidChainScanResult?
    ) -> TokenInfo? {
        guard let result = simulationResult else { return nil }

        // Check in approvals
        if let approvals = result.approvals {
            for approval in approvals {
                // Correctly compare contract address, not name/symbol
                if approval.contractAddress?.caseInsensitiveCompare(contractAddress) == .orderedSame {
                    let symbol = approval.symbol ?? approval.name ?? ""
                    let decimals = approval.decimals ?? 18 // Fallback for ERC20
                    return TokenInfo(
                        symbol: symbol,
                        decimals: decimals,
                        source: .blockaidDirect
                    )
                }
            }
        }

        // Check in assetsDiff
        if let assetsDiff = result.assetsDiff {
            let allAssets = assetsDiff.in + assetsDiff.out

            for asset in allAssets {
                // Correctly compare contract address, not name
                if asset.contractAddress?.caseInsensitiveCompare(contractAddress) == .orderedSame {
                    let symbol = asset.symbol ?? asset.name ?? ""
                    let decimals = asset.decimals ?? 18 // Fallback for ERC20
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

// MARK: - Mathematical Calculation

private extension WCApprovalHelpers {
    static func calculateFromBlockaidAmounts(
        contractAddress: String,
        originalAmount: BigUInt,
        simulationResult: BlockaidChainScanResult?
    ) -> TokenInfo? {
        guard let result = simulationResult else { return nil }

        // Search for corresponding asset and its amount
        var blockaidAmount: Decimal?
        var symbol: String?

        // Search in approvals
        if let approvals = result.approvals {
            for approval in approvals {
                if approval.contractAddress?.caseInsensitiveCompare(contractAddress) == .orderedSame {
                    symbol = approval.symbol ?? approval.name
                    // Approvals usually don't have specific amount
                    break
                }
            }
        }

        // Search in assetsDiff
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

        // If found amount, calculate decimals
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

    /// Calculates decimals where: originalAmount / 10^decimals ≈ blockaidAmount
    static func calculateDecimals(originalAmount: BigUInt, blockaidAmount: Decimal) -> Int {
        let originalDecimal = Decimal(string: String(originalAmount)) ?? 0

        // Test standard decimals values
        let standardDecimals = [0, 6, 8, 9, 12, 18]

        for decimals in standardDecimals {
            let divisor = Decimal(sign: .plus, exponent: decimals, significand: 1)
            let calculated = originalDecimal / divisor

            // Check match with 1% tolerance
            let difference = abs(calculated - blockaidAmount)
            let tolerance = max(blockaidAmount * 0.01, 0.001)

            if difference <= tolerance {
                return decimals
            }
        }

        return -1 // Could not determine
    }
}
