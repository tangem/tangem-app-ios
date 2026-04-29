//
//  WCTransactionSimulationDisplayServiceTests.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemLocalization
@testable import Tangem

final class WCTransactionSimulationDisplayServiceTests {
    private let sut = WCTransactionSimulationDisplayService()

    // MARK: - formatNonEditableApprovalAmount

    @Test
    func shouldFormatPermitAmountWithDecimals() {
        let asset = BlockaidChainScanResult.Asset(
            name: "USD Coin",
            assetType: "ERC20",
            amount: 11000000,
            symbol: "USDC",
            logoURL: nil,
            decimals: 6,
            contractAddress: "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
        )

        let result = sut.formatNonEditableApprovalAmount(asset: asset, tokenName: "USD Coin")

        #expect(result.contains("USDC"))
        #expect(!result.contains(Localization.wcCommonUnlimited))
        #expect(!result.contains("11000000"))
        #expect(result.contains("11"))
    }

    @Test
    func shouldFormatFractionalPermitAmount() {
        let asset = BlockaidChainScanResult.Asset(
            name: "USD Coin",
            assetType: "ERC20",
            amount: 2200000,
            symbol: "USDC",
            logoURL: nil,
            decimals: 6,
            contractAddress: "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
        )

        let result = sut.formatNonEditableApprovalAmount(asset: asset, tokenName: "USD Coin")

        #expect(result.contains("USDC"))
        #expect(!result.contains(Localization.wcCommonUnlimited))
        #expect(!result.contains("2200000"))
        #expect(result.contains("2"))
    }

    @Test
    func shouldShowUnlimitedWhenAmountIsNil() {
        let asset = BlockaidChainScanResult.Asset(
            name: "USD Coin",
            assetType: "ERC20",
            amount: nil,
            symbol: "USDC",
            logoURL: nil,
            decimals: 6,
            contractAddress: "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
        )

        let result = sut.formatNonEditableApprovalAmount(asset: asset, tokenName: "USD Coin")

        #expect(result.contains(Localization.wcCommonUnlimited))
    }

    @Test
    func shouldShowUnlimitedWhenAmountIsZero() {
        let asset = BlockaidChainScanResult.Asset(
            name: "Tether",
            assetType: "ERC20",
            amount: 0,
            symbol: "USDT",
            logoURL: nil,
            decimals: 6,
            contractAddress: "0xdac17f958d2ee523a2206206994597c13d831ec7"
        )

        let result = sut.formatNonEditableApprovalAmount(asset: asset, tokenName: "Tether")

        #expect(result.contains(Localization.wcCommonUnlimited))
    }

    @Test
    func shouldUseTokenNameWhenSymbolIsNil() {
        let asset = BlockaidChainScanResult.Asset(
            name: "SomeToken",
            assetType: "ERC20",
            amount: nil,
            symbol: nil,
            logoURL: nil,
            decimals: 18,
            contractAddress: "0x1234"
        )

        let result = sut.formatNonEditableApprovalAmount(asset: asset, tokenName: "SomeToken")

        #expect(result.contains("SomeToken"))
        #expect(result.contains(Localization.wcCommonUnlimited))
    }

    @Test
    func shouldHandleZeroDecimalsCorrectly() {
        let asset = BlockaidChainScanResult.Asset(
            name: "NFT Token",
            assetType: "ERC20",
            amount: 5,
            symbol: "NFT",
            logoURL: nil,
            decimals: 0,
            contractAddress: "0x5678"
        )

        let result = sut.formatNonEditableApprovalAmount(asset: asset, tokenName: "NFT Token")

        #expect(result.contains("5"))
        #expect(result.contains("NFT"))
        #expect(!result.contains(Localization.wcCommonUnlimited))
    }

    @Test
    func shouldHandleNilDecimalsAsZero() {
        let asset = BlockaidChainScanResult.Asset(
            name: nil,
            assetType: "ERC20",
            amount: 1000,
            symbol: "TKN",
            logoURL: nil,
            decimals: nil,
            contractAddress: "0xabcd"
        )

        let result = sut.formatNonEditableApprovalAmount(asset: asset, tokenName: "ERC20")

        #expect(result.contains("000"))
        #expect(result.contains("TKN"))
        #expect(!result.contains(Localization.wcCommonUnlimited))
    }

    // MARK: - createDisplayModel (integration)

    @Test
    func shouldCreateNonEditableApprovalForPermitWithAmount() {
        let asset = BlockaidChainScanResult.Asset(
            name: "USD Coin",
            assetType: "ERC20",
            amount: 11000000,
            symbol: "USDC",
            logoURL: nil,
            decimals: 6,
            contractAddress: "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
        )

        let simulationResult = BlockaidChainScanResult(
            validationStatus: .benign,
            validationDescription: "",
            assetsDiff: nil,
            approvals: [asset]
        )

        let model = sut.createDisplayModel(
            from: .simulationSucceeded(result: simulationResult),
            originalTransaction: nil,
            walletModels: [],
            onApprovalEdit: nil
        )

        guard case .success(let content) = model?.content,
              case .approvals(let section) = content.sections.first else {
            Issue.record("Expected approvals section")
            return
        }

        let item = section.items[0]
        #expect(item.isEditable == false)

        guard case .nonEditable = item.leftContent else {
            Issue.record("Expected nonEditable leftContent")
            return
        }

        guard case .tokenInfo(let formattedAmount, _, _) = item.rightContent else {
            Issue.record("Expected tokenInfo rightContent")
            return
        }

        #expect(formattedAmount.contains("11"))
        #expect(formattedAmount.contains("USDC"))
        #expect(!formattedAmount.contains(Localization.wcCommonUnlimited))
    }

    @Test
    func shouldCreateUnlimitedApprovalForPermitWithoutAmount() {
        let asset = BlockaidChainScanResult.Asset(
            name: "USD Coin",
            assetType: "ERC20",
            amount: nil,
            symbol: "USDC",
            logoURL: nil,
            decimals: 6,
            contractAddress: "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
        )

        let simulationResult = BlockaidChainScanResult(
            validationStatus: .benign,
            validationDescription: "",
            assetsDiff: nil,
            approvals: [asset]
        )

        let model = sut.createDisplayModel(
            from: .simulationSucceeded(result: simulationResult),
            originalTransaction: nil,
            walletModels: [],
            onApprovalEdit: nil
        )

        guard case .success(let content) = model?.content,
              case .approvals(let section) = content.sections.first else {
            Issue.record("Expected approvals section")
            return
        }

        let item = section.items[0]

        guard case .tokenInfo(let formattedAmount, _, _) = item.rightContent else {
            Issue.record("Expected tokenInfo rightContent")
            return
        }

        #expect(formattedAmount.contains(Localization.wcCommonUnlimited))
    }

    @Test
    func shouldReturnNilForSimulationNotSupported() {
        let model = sut.createDisplayModel(
            from: .simulationNotSupported(method: "personal_sign"),
            originalTransaction: nil,
            walletModels: [],
            onApprovalEdit: nil
        )

        #expect(model == nil)
    }

    @Test
    func shouldReturnNoChangesSectionWhenNoApprovalsOrDiffs() {
        let simulationResult = BlockaidChainScanResult(
            validationStatus: .benign,
            validationDescription: "",
            assetsDiff: nil,
            approvals: nil
        )

        let model = sut.createDisplayModel(
            from: .simulationSucceeded(result: simulationResult),
            originalTransaction: nil,
            walletModels: [],
            onApprovalEdit: nil
        )

        guard case .success(let content) = model?.content else {
            Issue.record("Expected success content")
            return
        }

        #expect(content.sections.contains { section in
            if case .noChanges = section { return true }
            return false
        })
    }
}
