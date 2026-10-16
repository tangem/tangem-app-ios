//
//  TransactionDetailsApproveContentTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import BlockchainSdk
import TangemExpress
import TangemFoundation
import TangemLocalization
import TangemSdk
@testable import Tangem

extension TransactionHistoryAuxDataRepositoryDependentTests {
    @Suite("TransactionDetailsFactory approve content")
    final class TransactionDetailsApproveContentTests {
        private static let blockchain = Blockchain.ethereum(testnet: false)
        private static let usdtContract = "0xdAC17F958D2ee523a2206206994597C13D831ec7"
        private static let spender = "0x1231DEB6f5749EF6cE6943a275A1D3E7486F4EaE"

        private let auxDataRepository = TransactionHistoryAuxDataRepositoryStub()

        @Test("Shows the approved amount with the ticker after the number, whatever the locale")
        func amountPutsTickerAfterNumber() async throws {
            let (transaction, content) = await withStubbedDependencies { makeContent() }
            let data = try #require(content)
            let single = try #require(data.tokens?.single)

            #expect(single.caption == Localization.transactionHistoryApprovedAmount)
            #expect(single.amountText == transaction.amount.amountWithCurrencyCode)
            #expect(single.amountText == "1,234.5678\u{a0}USDT")
            #expect(data.counterparty == nil)
        }

        @Test("Resolves the icon of an approved token outside the account among the tokens known on the network")
        func iconOfTokenOutsideAccountIsResolved() async throws {
            let usdt = TokenItem.token(
                Token(name: "Tether", symbol: "USDT", contractAddress: Self.usdtContract, decimalCount: 6),
                BlockchainNetwork(Self.blockchain, derivationPath: nil)
            )
            auxDataRepository.register(
                usdt,
                for: ExpressCurrency(contractAddress: Self.usdtContract.lowercased(), network: Self.blockchain.networkId)
            )

            let single = try await withStubbedDependencies {
                try #require(makeContent().content?.tokens?.single)
            }

            #expect(single.icon == .token(TokenIconInfoBuilder().build(from: usdt, isCustom: false)))
        }

        @Test("Takes the icon of an approved token held under several derivations from the approving wallet's derivation")
        func iconOfTokenUnderSeveralDerivationsComesFromApprovingWallet() async throws {
            let token = Token(name: "Tether", symbol: "USDT", contractAddress: Self.usdtContract, decimalCount: 6, id: "tether")
            let customDerivationToken = TokenItem.token(
                token,
                BlockchainNetwork(Self.blockchain, derivationPath: try DerivationPath(rawPath: "m/44'/60'/1'/0/0"))
            )
            let approvingWalletToken = TokenItem.token(token, BlockchainNetwork(Self.blockchain, derivationPath: nil))

            let walletModelsManager = WalletModelsManagerTestsMock()
            walletModelsManager.walletModels = [
                WalletModelTestsMock(tokenItem: customDerivationToken, isEmpty: false, isCustom: true),
                WalletModelTestsMock(tokenItem: approvingWalletToken, isEmpty: false),
            ]
            let account = CryptoAccountModelMock(isMainAccount: true, walletModelsManager: walletModelsManager, onArchive: { _ in })

            let single = try await withStubbedDependencies {
                try #require(makeContent(account: account).content?.tokens?.single)
            }

            #expect(single.icon == .token(TokenIconInfoBuilder().build(from: approvingWalletToken, isCustom: false)))
        }

        @Test("Falls back to the network icon when the approved token can't be resolved")
        func iconOfUnresolvedTokenFallsBackToNetwork() async throws {
            let single = try await withStubbedDependencies {
                try #require(makeContent().content?.tokens?.single)
            }

            #expect(single.icon == .unresolved(network: NetworkImageProvider().provide(by: Self.blockchain, filled: true)))
        }
    }
}

// MARK: - Helpers

private extension TransactionHistoryAuxDataRepositoryDependentTests.TransactionDetailsApproveContentTests {
    func withStubbedDependencies<T>(_ operation: () throws -> T) async rethrows -> T {
        try await InjectedDependenciesIsolation.shared.run {
            let previousAuxDataRepository = InjectedValues[\.transactionHistoryAuxDataRepository]
            InjectedValues[\.transactionHistoryAuxDataRepository] = auxDataRepository
            defer { InjectedValues[\.transactionHistoryAuxDataRepository] = previousAuxDataRepository }
            return try operation()
        }
    }

    func makeContent(account: (any CryptoAccountModel)? = nil) -> (transaction: TransactionViewModel, content: TransactionDetailsGenericOperationViewData?) {
        let record = makeApproveRecord()
        let walletModel = CommonWalletModel.previewWalletModel(history: [record])
        if let account {
            walletModel.setCryptoAccount(account)
        }
        let context = TransactionDetailsContext(walletModel: walletModel, userWalletInfo: makeUserWalletInfo(), isAccountsMode: false)
        let mapper = TransactionHistoryMapper(
            currencySymbol: "ETH",
            blockchain: Self.blockchain,
            addressesProvider: walletModel,
            showSign: true,
            isToken: false,
            stakingNetwork: nil
        )
        let transaction = mapper.mapTransactionViewModel(record)
        let addContactHelper = TransactionDetailsAddContactHelper(
            networkId: AddressBookNetworkID(Self.blockchain.networkId),
            contacts: [],
            isAddressBookSynced: true,
            transactionType: transaction.transactionType,
            interactionAddress: transaction.interactionAddress
        )

        let content = TransactionDetailsFactory.reduce(
            transaction: transaction,
            record: record,
            cryptoAmount: 0,
            context: context,
            addContactHelper: addContactHelper
        ).content

        guard case .generic(let data) = content else {
            return (transaction, nil)
        }

        return (transaction, data)
    }

    func makeApproveRecord() -> TransactionRecord {
        TransactionRecord(
            hash: "0xapproved",
            index: 0,
            source: .single(.init(address: "0xtestaddress", amount: 0)),
            destination: .single(.init(address: .contract(Self.usdtContract), amount: 0)),
            fee: Fee(Amount(with: Self.blockchain, value: 0.001)),
            status: .confirmed,
            isOutgoing: true,
            type: .approve(.init(spender: Self.spender, symbol: "USDT", allowance: .limited(1234.5678))),
            date: Date(),
            tokenTransfers: [],
            nonce: nil
        )
    }

    func makeUserWalletInfo() -> UserWalletInfo {
        UserWalletInfo(
            name: "Test",
            id: UserWalletId(value: Data([0x01, 0x02, 0x03])),
            config: UserWalletConfigStub(),
            backupState: .valid,
            refcode: nil,
            signerFactory: TangemSignerFactory(),
            emailDataProvider: EmailDataProviderStub()
        )
    }
}

private extension TransactionDetailsTokensViewData {
    var single: Single? {
        guard case .single(let single) = content else {
            return nil
        }

        return single
    }
}
