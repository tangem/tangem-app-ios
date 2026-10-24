//
//  TransactionDetailsYieldFeeTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import BlockchainSdk
import TangemFoundation
import TangemAssets
@testable import Tangem

extension TransactionHistoryAuxDataRepositoryDependentTests {
    @Suite("TransactionDetailsFactory supply to and withdrawal from Aave")
    final class TransactionDetailsYieldFeeTests {
        private static let blockchain = Blockchain.polygon(testnet: false)
        private static let walletAddress = "0xwallet"
        private static let aToken = "0xA4D94019934D8333Ef880ABFFbF2FDd611C762BD"
        private static let quote = TokenQuote(
            currencyId: blockchain.currencyId,
            price: 1,
            priceUsd: 1,
            priceChange24h: nil,
            priceChange7d: nil,
            priceChange30d: nil,
            currencyCode: "USD"
        )

        private let auxDataRepository = TransactionHistoryAuxDataRepositoryStub()

        @Test("The wallet's own Yield-mode send shows the fee it paid on the withdrawal it made")
        func aWithdrawalTheWalletSentShowsItsFee() async throws {
            let content = try await withStubbedDependencies {
                try #require(makeYieldContent(methodName: "yieldSend", isOutgoing: false, status: .confirmed))
            }

            #expect(content.info?.rows.contains { $0.id == "networkFee" } == true)
        }

        @Test("A gasless send shows no fee on the withdrawal: its gas was paid by the relayer")
        func aWithdrawalTheRelayerSentShowsNoFee() async throws {
            let content = try await withStubbedDependencies {
                try #require(makeYieldContent(methodName: "gaslessTransaction", isOutgoing: false, status: .confirmed))
            }

            #expect(content.info?.rows.contains { $0.id == "networkFee" } != true)
        }

        @Test(
            "Withdrawn and Supplied pair the token with Aave, price it and sign it by where the funds go",
            arguments: [("yieldSend", false, AppConstants.plusSign), ("yieldTopup", true, AppConstants.minusSign)]
        )
        func supplyAndWithdrawalPairTheTokenWithAave(methodName: String, isOutgoing: Bool, sign: String) async throws {
            let content = try await withStubbedDependencies {
                try #require(makeYieldContent(methodName: methodName, isOutgoing: isOutgoing, status: .confirmed))
            }

            #expect(content.tokens.provider == .trailing(Assets.YieldModule.yieldModuleAaveLogo))
            #expect(content.tokens.caption == nil)
            #expect(content.tokens.fiatText != nil)
            #expect(content.tokens.amountText.hasPrefix(sign))
            #expect(!content.tokens.isAmountStrikethrough)
        }

        @Test("A failed Supply strikes its amount through, like every other failed operation")
        func failedSupplyStrikesItsAmountThrough() async throws {
            let content = try await withStubbedDependencies {
                try #require(makeYieldContent(methodName: "yieldTopup", isOutgoing: true, status: .failed))
            }

            #expect(content.tokens.isAmountStrikethrough)
        }

        @Test(
            "Enabling and disabling Yield Mode keep their caption and get no fiat line",
            arguments: [("yieldEnter", true), ("yieldWithdraw", false)]
        )
        func enableAndDisableKeepTheirLayout(methodName: String, isOutgoing: Bool) async throws {
            let content = try await withStubbedDependencies {
                try #require(makeYieldContent(methodName: methodName, isOutgoing: isOutgoing, status: .confirmed))
            }

            #expect(content.tokens.caption != nil)
            #expect(content.tokens.fiatText == nil)
        }

        @Test(
            "Only Withdrawn and Supplied head the sheet with the yield lightning",
            arguments: [
                ("yieldSend", false, DesignSystem.Icons.Lightning.regular20),
                ("yieldTopup", true, DesignSystem.Icons.Lightning.regular20),
                ("yieldSend", true, nil),
                ("yieldEnter", true, nil),
                ("yieldWithdraw", false, nil),
            ] as [(String, Bool, ImageType?)]
        )
        func onlySupplyAndWithdrawalShowTheLightning(methodName: String, isOutgoing: Bool, glyph: ImageType?) async throws {
            let header = try await withStubbedDependencies {
                makeDetails(methodName: methodName, isOutgoing: isOutgoing, status: .confirmed).header
            }

            #expect(header.iconGlyph == glyph)
        }

        @Test("Withdrawn offers to explore Aave, like every other Yield-mode operation")
        func withdrawalOffersToExploreAave() async throws {
            let header = try await withStubbedDependencies {
                makeDetails(methodName: "yieldSend", isOutgoing: false, status: .confirmed).header
            }

            #expect(header.menuSections.flatMap(\.actions).contains { $0.id == "exploreProvider" })
        }
    }
}

// MARK: - Helpers

private extension TransactionHistoryAuxDataRepositoryDependentTests.TransactionDetailsYieldFeeTests {
    func withStubbedDependencies<T>(_ operation: () throws -> T) async throws -> T {
        try await InjectedDependenciesIsolation.shared.run {
            let previousAuxDataRepository = InjectedValues[\.transactionHistoryAuxDataRepository]
            let previousQuotesRepository = try #require(
                InjectedValues[\.quotesRepository] as? TokenQuotesRepository & TokenQuotesRepositoryUpdater
            )
            InjectedValues[\.transactionHistoryAuxDataRepository] = auxDataRepository
            InjectedValues.setTokenQuotesRepository(MockTokenQuotesRepository(quotes: [Self.blockchain.currencyId: Self.quote]))
            defer {
                InjectedValues[\.transactionHistoryAuxDataRepository] = previousAuxDataRepository
                InjectedValues.setTokenQuotesRepository(previousQuotesRepository)
            }
            return try operation()
        }
    }

    func makeYieldContent(
        methodName: String,
        isOutgoing: Bool,
        status: TransactionRecord.TransactionStatus
    ) -> TransactionDetailsYieldViewData? {
        guard case .yield(let data) = makeDetails(methodName: methodName, isOutgoing: isOutgoing, status: status).content else {
            return nil
        }

        return data
    }

    func makeDetails(
        methodName: String,
        isOutgoing: Bool,
        status: TransactionRecord.TransactionStatus
    ) -> (header: TransactionDetailsHeaderViewData, content: TransactionDetailsViewModel.Content) {
        let record = TransactionRecord(
            hash: "0xwithdrawal",
            index: 0,
            source: .single(.init(address: isOutgoing ? Self.walletAddress : Self.aToken, amount: 0.03)),
            destination: .single(.init(address: .user(isOutgoing ? Self.aToken : Self.walletAddress), amount: 0.03)),
            fee: Fee(Amount(with: Self.blockchain, value: 0.15)),
            status: status,
            isOutgoing: isOutgoing,
            type: .contractMethodName(name: methodName),
            date: Date(),
            tokenTransfers: [],
            isFromYieldContract: !isOutgoing,
            nonce: nil
        )
        let walletModel = CommonWalletModel.previewWalletModel(history: [record], blockchain: Self.blockchain)
        let userWalletInfo = UserWalletInfo(
            name: "Test",
            id: UserWalletId(value: Data([0x01, 0x02, 0x03])),
            config: UserWalletConfigStub(),
            backupState: .valid,
            refcode: nil,
            signerFactory: TangemSignerFactory(),
            emailDataProvider: EmailDataProviderStub()
        )
        let context = TransactionDetailsContext(walletModel: walletModel, userWalletInfo: userWalletInfo, isAccountsMode: false)
        let mapper = TransactionHistoryMapper(
            currencySymbol: "USDC",
            blockchain: Self.blockchain,
            addressesProvider: walletModel,
            showSign: true,
            isToken: true,
            stakingNetwork: nil
        )
        let transaction = mapper.mapTransactionViewModel(record)
        let addContactHelper = TransactionDetailsAddContactHelper(
            networkId: AddressBookNetworkID(Self.blockchain.networkId),
            contacts: [],
            isAddressBookSynced: true,
            transactionType: transaction.transactionType,
            interactionAddress: transaction.interactionAddress,
            subtitleOwner: transaction.subtitleOwner
        )

        return TransactionDetailsFactory.reduce(
            transaction: transaction,
            record: record,
            cryptoAmount: 0.03,
            context: context,
            addContactHelper: addContactHelper
        )
    }
}
