//
//  SubtitleOwnerResolverTangemPayTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import BlockchainSdk
import TangemFoundation
@testable import Tangem

@Suite("Subtitle owner of a Tangem Pay deposit address")
struct SubtitleOwnerResolverTangemPayTests {
    @Test("The current wallet's Pay deposit address resolves to its Pay account whatever the casing")
    func currentWalletPayAccount() throws {
        let owner = try makeOwner(userWalletId: Self.currentWalletId)

        let resolved = makeResolver(owners: [owner]).resolve(
            address: Self.depositAddress.lowercased(),
            blockchain: .polygon(testnet: false)
        )

        #expect(resolved == .accountInCurrentWallet(name: owner.name, icon: owner.icon))
        #expect(resolved?.isOwnWallet == true)
    }

    @Test("Another wallet's Pay deposit address resolves to that wallet's Pay account")
    func otherWalletPayAccount() throws {
        let owner = try makeOwner(userWalletId: Self.otherWalletId)

        let resolved = makeResolver(owners: [owner]).resolve(
            address: Self.depositAddress,
            blockchain: .polygon(testnet: false)
        )

        #expect(resolved == .accountInOtherWallet(accountName: owner.name, accountIcon: owner.icon))
    }

    @Test("A Pay deposit address stays an outside address on a network the account has no deposit address on")
    func otherNetworkStaysUnresolved() throws {
        let owner = try makeOwner(userWalletId: Self.currentWalletId)

        let resolved = makeResolver(owners: [owner]).resolve(
            address: Self.depositAddress,
            blockchain: .ethereum(testnet: false)
        )

        #expect(isUnresolved(resolved))
    }

    @Test("A mainnet Pay deposit address stays an outside address on the same network's testnet")
    func testnetStaysUnresolved() throws {
        let owner = try makeOwner(userWalletId: Self.currentWalletId)

        let resolved = makeResolver(owners: [owner]).resolve(
            address: Self.depositAddress,
            blockchain: .polygon(testnet: true)
        )

        #expect(isUnresolved(resolved))
    }

    @Test("Without a Pay account the address stays an outside address")
    func noPayAccountStaysUnresolved() {
        let resolved = makeResolver(owners: []).resolve(
            address: Self.depositAddress,
            blockchain: .polygon(testnet: false)
        )

        #expect(isUnresolved(resolved))
    }

    private static let currentWalletId = UserWalletId(value: Data([1]))
    private static let otherWalletId = UserWalletId(value: Data([2]))
    private static let depositAddress = "0x3796Ab0e1d5C2a4A7b8e4f1C9D0a2B3c4D5e89b4"

    private func makeResolver(owners: [TangemPayDepositOwner]) -> SubtitleOwnerResolver {
        SubtitleOwnerResolver(
            blockchain: .polygon(testnet: false),
            currentUserWalletId: Self.currentWalletId,
            isAccountsMode: false,
            contacts: [],
            tangemPayDepositOwners: owners
        )
    }

    private func makeOwner(userWalletId: UserWalletId) throws -> TangemPayDepositOwner {
        let networks = try makeTangemPayNetworks(
            """
            [
              {
                "name": "\(Blockchain.polygon(testnet: false).networkId)",
                "isTestnet": false,
                "chainId": 137,
                "status": "ENABLED",
                "depositAddress": "\(Self.depositAddress)",
                "tokens": [{ "token": "USDC", "tokenContractAddress": "0x3c499c542cef5e3811e1192ce70d8cc03d5c3359" }]
              }
            ]
            """
        )

        return TangemPayDepositOwner(
            userWalletId: userWalletId,
            name: "Payment account",
            icon: AccountModelUtils.UI.iconViewData(icon: AccountModel.StandaloneIcon.tangemPay.erased, accountName: "Payment account"),
            entries: TangemPayAccountTokensResolver.makeEntries(from: networks)
        )
    }

    private func isUnresolved(_ owner: TransactionViewModel.SubtitleOwner?) -> Bool {
        if case .unresolved = owner {
            return true
        }

        return false
    }
}
