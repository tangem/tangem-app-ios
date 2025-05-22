//
//  BlockaidMapper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

enum BlockaidMapper {
    static func mapBlockchainScan(_ response: BlockaidDTO.EvmScan.Response) -> BlockaidChainScanResult {
        let validationStatus = response.validation.flatMap { mapToValidationResult(from: $0.resultType) }

        let assetsDiffValues: [BlockaidDTO.EvmScan.AssetDiff] = response.simulation?.assetsDiffs ?? []

        let assetsDiff = mapToAssetsDiffs(from: assetsDiffValues)

        let approvals = response.simulation?.exposures.flatMap { mapToApprovals(from: $0.values.flatMap { $0 }) }

        return BlockaidChainScanResult(validationStatus: validationStatus, assetsDiff: assetsDiff, approvals: approvals)
    }

    static func mapBlockchainScan(_ response: BlockaidDTO.SolanaScan.Response) -> BlockaidChainScanResult {
        let validationStatus = response.result.validation.flatMap { mapToValidationResult(from: $0.resultType) }
        let assetsDiffs = response.result.simulation.flatMap {
            mapToAssetsDiffs(from: $0.accountSummary.accountAssetsDiff)
        }

        return BlockaidChainScanResult(validationStatus: validationStatus, assetsDiff: assetsDiffs, approvals: nil)
    }
}

private extension BlockaidMapper {
    static func mapToValidationResult(from result: BlockaidDTO.ResultType) -> BlockaidChainScanResult.ValidationStatus? {
        switch result {
        case .malicious: .malicious
        case .warning: .warning
        case .benign: .benign
        case .info, .error: nil
        }
    }

    static func mapToAssetsDiffs(from assetsDiffs: [BlockaidDTO.EvmScan.AssetDiff]) -> BlockaidChainScanResult.AssetDiff {
        let inAssets = assetsDiffs.flatMap { assetDiff -> [BlockaidChainScanResult.Asset] in
            return mapEVMAsset(assetDiff, transactions: assetDiff.in)
        }

        let outAssets = assetsDiffs.flatMap { assetDiff -> [BlockaidChainScanResult.Asset] in
            return mapEVMAsset(assetDiff, transactions: assetDiff.out)
        }
        return .init(in: inAssets, out: outAssets)
    }

    static func mapToAssetsDiffs(from assetsDiffs: [BlockaidDTO.SolanaScan.AssetDiff]) -> BlockaidChainScanResult.AssetDiff {
        let inAssets = assetsDiffs.compactMap { assetDiff -> BlockaidChainScanResult.Asset? in
            guard let inTransaction = assetDiff.in else { return nil }
            return mapSolanaAsset(assetDiff, amount: inTransaction.value)
        }

        let outAssets = assetsDiffs.compactMap { assetDiff -> BlockaidChainScanResult.Asset? in
            guard let outTransaction = assetDiff.out else { return nil }
            return mapSolanaAsset(assetDiff, amount: outTransaction.value)
        }
        return .init(in: inAssets, out: outAssets)
    }

    static func mapToApprovals(from exposures: [BlockaidDTO.Exposure]) -> [BlockaidChainScanResult.Asset] {
        exposures.flatMap { exposure in
            exposure.spenders.flatMap { key, spenderDetails in
                spenderDetails.exposure.map {
                    BlockaidChainScanResult.Asset(
                        assetType: exposure.assetType,
                        amount: $0.value,
                        symbol: exposure.asset.symbol,
                        logoURL: exposure.asset.logoURL.flatMap { URL(string: $0) }
                    )
                }
            }
        }
    }

    static func mapSolanaAsset(
        _ assetDiff: BlockaidDTO.SolanaScan.AssetDiff,
        amount: Decimal
    ) -> BlockaidChainScanResult.Asset {
        BlockaidChainScanResult.Asset(
            assetType: assetDiff.assetType,
            amount: amount,
            symbol: assetDiff.asset.symbol,
            logoURL: assetDiff.asset.logoURL.flatMap { URL(string: $0) }
        )
    }

    static func mapEVMAsset(
        _ assetDiff: BlockaidDTO.EvmScan.AssetDiff,
        transactions: [BlockaidDTO.TransactionDetail]
    ) -> [BlockaidChainScanResult.Asset] {
        transactions.map { transaction in
            BlockaidChainScanResult.Asset(
                assetType: assetDiff.assetType,
                amount: transaction.value,
                symbol: assetDiff.asset.symbol,
                logoURL: assetDiff.asset.logoURL.flatMap { URL(string: $0) }
            )
        }
    }
}
