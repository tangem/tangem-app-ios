//
//  TransactionHistoryMapperTangemPayTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import BlockchainSdk
import TangemFoundation
import TangemLocalization
@testable import Tangem

@Suite("Transaction history rows exchanged with the own Tangem Pay account")
struct TransactionHistoryMapperTangemPayTests {
    @Test("A send to the Pay deposit address is a transfer to the Payment account")
    func sendToPayAccount() throws {
        let owner = try makeOwner()

        let viewModel = makeSUT().mapTransactionViewModel(
            makeRecord(
                source: Self.walletAddress,
                destination: Self.depositAddress,
                isOutgoing: true,
                type: .transfer
            ),
            subtitleOwnerResolver: makeResolver(owner: owner)
        )

        #expect(viewModel.display.title.fullText == Localization.commonTransferred)
        #expect(viewModel.display.subtitle == .owner(direction: .outgoing, owner: .accountInCurrentWallet(name: owner.name, icon: owner.icon)))
    }

    @Test("A withdrawal from Pay, an unrecognised contract call, is a transfer from the Payment account")
    func withdrawalFromPayAccount() throws {
        let owner = try makeOwner()

        let viewModel = makeSUT().mapTransactionViewModel(
            makeRecord(
                source: Self.depositAddress,
                destination: Self.walletAddress,
                isOutgoing: false,
                type: .contractMethodIdentifier(id: "0x4b268241")
            ),
            subtitleOwnerResolver: makeResolver(owner: owner)
        )

        #expect(viewModel.display.title.fullText == Localization.commonTransferred)
        #expect(viewModel.display.subtitle == .owner(direction: .incoming, owner: .accountInCurrentWallet(name: owner.name, icon: owner.icon)))
    }

    private static let walletId = UserWalletId(value: Data([1]))
    private static let walletAddress = "0xaa5c0cc6d3f2db76d4d37bc3daa2abce3be4523f"
    private static let depositAddress = "0x37960c48ebdcf1007d242db9fd29a86527e389b4"

    private func makeSUT() -> Tangem.TransactionHistoryMapper {
        Tangem.TransactionHistoryMapper(
            currencySymbol: "USDC",
            blockchain: .polygon(testnet: false),
            addressesProvider: StubTransactionHistoryAddressesProvider(walletAddresses: [Self.walletAddress]),
            showSign: true,
            isToken: true,
            stakingNetwork: nil
        )
    }

    private func makeResolver(owner: TangemPayDepositOwner) -> SubtitleOwnerResolver {
        SubtitleOwnerResolver(
            blockchain: .polygon(testnet: false),
            currentUserWalletId: Self.walletId,
            isAccountsMode: true,
            contacts: [],
            tangemPayDepositOwners: [owner]
        )
    }

    private func makeOwner() throws -> TangemPayDepositOwner {
        let networks = try makeTangemPayNetworks(
            """
            [
              {
                "name": "polygon-pos",
                "isTestnet": false,
                "chainId": 137,
                "status": "ENABLED",
                "depositAddress": "0x37960c48EBDCf1007d242Db9fD29a86527E389b4",
                "tokens": [{ "token": "USDC", "tokenContractAddress": "0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359" }]
              }
            ]
            """
        )

        return TangemPayDepositOwner(
            userWalletId: Self.walletId,
            name: "Payment account",
            icon: AccountModelUtils.UI.iconViewData(icon: AccountModel.StandaloneIcon.tangemPay.erased, accountName: "Payment account"),
            entries: TangemPayAccountTokensResolver.makeEntries(from: networks)
        )
    }

    private func makeRecord(
        source: String,
        destination: String,
        isOutgoing: Bool,
        type: TransactionRecord.TransactionType
    ) -> TransactionRecord {
        TransactionRecord(
            hash: "hash",
            index: 0,
            source: .single(TransactionRecord.Source(address: source, amount: 1)),
            destination: .single(TransactionRecord.Destination(address: .user(destination), amount: 1)),
            fee: Fee(Amount(type: .coin, currencySymbol: "POL", value: 1, decimals: 18)),
            status: .confirmed,
            isOutgoing: isOutgoing,
            type: type,
            date: Date(),
            tokenTransfers: [],
            isFromYieldContract: false,
            nonce: nil
        )
    }
}

// MARK: - Stubs

private struct StubTransactionHistoryAddressesProvider: WalletModelTransactionHistoryAddressesProvider {
    let walletAddresses: [String]
}
