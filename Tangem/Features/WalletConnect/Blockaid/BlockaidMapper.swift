//
//  BlockaidMapper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

enum BlockaidMapper {
    static func mapBlockchainScan(_ response: BlockaidDTO.EvmScan.Response) throws -> BlockaidChainScanResult {
        guard response.simulation?.status == .success else { throw "Simulation failed \(response.validation?.error ?? "")" }

        let validationStatus = response.validation.flatMap { mapToValidationResult(from: $0.resultType) }

        let assetsDiffValues: [String: [BlockaidDTO.EvmScan.AssetDiff]] = response.simulation?.assetsDiffs ?? [:]

        let assetsDiff = mapToAssetsDiffs(from: assetsDiffValues[response.accountAddress ?? ""] ?? [])

        let approvals = response.simulation?.exposures.flatMap { mapToApprovals(from: $0.values.flatMap { $0 }) }

        return BlockaidChainScanResult(
            validationStatus: validationStatus,
            validationDescription: response.validation?.description,
            assetsDiff: assetsDiff,
            approvals: approvals
        )
    }

    static func mapBlockchainScan(_ response: BlockaidDTO.SolanaScan.Response) -> BlockaidChainScanResult {
        let validationStatus = response.result.validation.flatMap { mapToValidationResult(from: $0.resultType) }
        let assetsDiffs = response.result.simulation.flatMap {
            mapToAssetsDiffs(from: $0.accountSummary.accountAssetsDiff)
        }

        return BlockaidChainScanResult(
            validationStatus: validationStatus,
            validationDescription: response.result.validation?.description,
            assetsDiff: assetsDiffs,
            approvals: nil
        )
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
        return exposures.flatMap { exposure in
            exposure.spenders?.compactMap { _, detail in
                // 1) ERC-721: setApprovalForAll
                if detail.isApprovedForAll == true {
                    return makeApprovalAsset(
                        assetType: exposure.assetType,
                        name: exposure.asset.name,
                        symbol: exposure.asset.symbol,
                        logoURL: exposure.asset.logoUrl,
                        decimals: exposure.asset.decimals,
                        contractAddress: exposure.asset.address
                    )
                }

                // 2) ERC-20: infinite approve (0xffff…)
                if let approval = detail.approval?
                    .lowercased(),
                    approval.hasPrefix("0xffff") {
                    return makeApprovalAsset(
                        assetType: exposure.assetType,
                        name: exposure.asset.name,
                        symbol: exposure.asset.symbol,
                        logoURL: exposure.asset.logoUrl,
                        decimals: exposure.asset.decimals,
                        contractAddress: exposure.asset.address
                    )
                }

                return nil
            } ?? []
        }
    }

    private static func makeApprovalAsset(
        assetType: String,
        name: String?,
        symbol: String?,
        logoURL: String?,
        decimals: Int?,
        contractAddress: String?
    ) -> BlockaidChainScanResult.Asset {
        BlockaidChainScanResult.Asset(
            name: name,
            assetType: assetType,
            amount: nil,
            symbol: symbol,
            logoURL: logoURL.flatMap(URL.init(string:)),
            decimals: decimals,
            contractAddress: contractAddress
        )
    }

    static func mapSolanaAsset(
        _ assetDiff: BlockaidDTO.SolanaScan.AssetDiff,
        amount: Decimal?
    ) -> BlockaidChainScanResult.Asset {
        BlockaidChainScanResult.Asset(
            name: assetDiff.asset.name,
            assetType: assetDiff.assetType,
            amount: amount,
            symbol: assetDiff.asset.symbol,
            logoURL: assetDiff.asset.logoUrl.flatMap { URL(string: $0) },
            decimals: assetDiff.asset.decimals,
            contractAddress: assetDiff.asset.address
        )
    }

    static func mapEVMAsset(
        _ assetDiff: BlockaidDTO.EvmScan.AssetDiff,
        transactions: [BlockaidDTO.TransactionDetail]
    ) -> [BlockaidChainScanResult.Asset] {
        transactions.map { transaction in
            BlockaidChainScanResult.Asset(
                name: assetDiff.asset.name,
                assetType: assetDiff.assetType,
                amount: transaction.value,
                symbol: assetDiff.asset.symbol,
                logoURL: assetDiff.asset.logoUrl.flatMap {
                    URL(string: $0)
                },
                decimals: assetDiff.asset.decimals,
                contractAddress: assetDiff.asset.address
            )
        }
    }
}
