//
//  SolanaTokenAccountSelectorTests.swift
//  BlockchainSdkTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import SolanaSwift
import Testing
@testable import BlockchainSdk

struct SolanaTokenAccountSelectorTests {
    private let owner = "Cw3YcfqzRSa7xT7ecpR5E4FKDQU6aaxz5cWje366CZbf"
    private let mint = "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"
    private let anotherMint = "Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB"
    private let nonAssociatedAddress = "BmAzxn8WLYU3gEw79ATUdSUkMT53MeS5LjapBQB8gTPJ"

    @Test
    func prefersAssociatedTokenAccountWhenItIsNotFirst() throws {
        let associatedAddress = try associatedTokenAddress(owner: owner, mint: mint)
        let accounts = [
            account(address: nonAssociatedAddress, mint: mint, balance: 100),
            account(address: associatedAddress, mint: mint, balance: 1),
        ]

        let result = SolanaTokenAccountSelector.uniqueAccountsByMint(accounts, ownerAccountId: owner)

        #expect(result.count == 1)
        #expect(result[mint]?.address == associatedAddress)
        #expect(result[mint]?.balance == 1)
    }

    @Test
    func prefersAssociatedTokenAccountWhenItIsFirst() throws {
        let associatedAddress = try associatedTokenAddress(owner: owner, mint: mint)
        let accounts = [
            account(address: associatedAddress, mint: mint, balance: 1),
            account(address: nonAssociatedAddress, mint: mint, balance: 100),
        ]

        let result = SolanaTokenAccountSelector.uniqueAccountsByMint(accounts, ownerAccountId: owner)

        #expect(result[mint]?.address == associatedAddress)
        #expect(result[mint]?.balance == 1)
    }

    @Test
    func prefersToken2022AssociatedTokenAccount() throws {
        let associatedAddress = try associatedTokenAddress(owner: owner, mint: mint, programId: .token2022ProgramId)
        let accounts = [
            account(address: nonAssociatedAddress, mint: mint, balance: 50),
            account(address: associatedAddress, mint: mint, balance: 7),
        ]

        let result = SolanaTokenAccountSelector.uniqueAccountsByMint(accounts, ownerAccountId: owner)

        #expect(result[mint]?.address == associatedAddress)
        #expect(result[mint]?.balance == 7)
    }

    @Test
    func fallsBackToFirstAccountWhenAssociatedTokenAccountIsMissing() {
        let anotherNonAssociatedAddress = "2gVkYWexTHR5Hb2aLeQN3tnngvWzisFKXDUPrgMHpdST"
        let accounts = [
            account(address: nonAssociatedAddress, mint: mint, balance: 3),
            account(address: anotherNonAssociatedAddress, mint: mint, balance: 9),
        ]

        let result = SolanaTokenAccountSelector.uniqueAccountsByMint(accounts, ownerAccountId: owner)

        #expect(result[mint]?.address == nonAssociatedAddress)
        #expect(result[mint]?.balance == 3)
    }

    @Test
    func selectsAssociatedTokenAccountIndependentlyPerMint() throws {
        let firstAssociatedAddress = try associatedTokenAddress(owner: owner, mint: mint)
        let secondAssociatedAddress = try associatedTokenAddress(owner: owner, mint: anotherMint)
        let accounts = [
            account(address: nonAssociatedAddress, mint: mint, balance: 40),
            account(address: firstAssociatedAddress, mint: mint, balance: 2),
            account(address: nonAssociatedAddress, mint: anotherMint, balance: 80),
            account(address: secondAssociatedAddress, mint: anotherMint, balance: 5),
        ]

        let result = SolanaTokenAccountSelector.uniqueAccountsByMint(accounts, ownerAccountId: owner)

        #expect(result.count == 2)
        #expect(result[mint]?.address == firstAssociatedAddress)
        #expect(result[mint]?.balance == 2)
        #expect(result[anotherMint]?.address == secondAssociatedAddress)
        #expect(result[anotherMint]?.balance == 5)
    }

    @Test
    func returnsEmptyDictionaryForEmptyInput() {
        let result = SolanaTokenAccountSelector.uniqueAccountsByMint([], ownerAccountId: owner)
        #expect(result.isEmpty)
    }

    @Test
    func prefersAssociatedTokenAccountAddressWhenItIsNotFirst() throws {
        let associatedAddress = try associatedTokenAddress(owner: owner, mint: mint)
        let result = SolanaTokenAccountSelector.preferredAccountAddress(
            from: [nonAssociatedAddress, associatedAddress],
            mint: mint,
            ownerAccountId: owner
        )

        #expect(result == associatedAddress)
    }

    @Test
    func prefersToken2022AssociatedTokenAccountAddress() throws {
        let associatedAddress = try associatedTokenAddress(owner: owner, mint: mint, programId: .token2022ProgramId)
        let result = SolanaTokenAccountSelector.preferredAccountAddress(
            from: [nonAssociatedAddress, associatedAddress],
            mint: mint,
            ownerAccountId: owner
        )

        #expect(result == associatedAddress)
    }

    @Test
    func fallsBackToFirstAddressWhenAssociatedTokenAccountIsMissing() {
        let anotherNonAssociatedAddress = "2gVkYWexTHR5Hb2aLeQN3tnngvWzisFKXDUPrgMHpdST"
        let result = SolanaTokenAccountSelector.preferredAccountAddress(
            from: [nonAssociatedAddress, anotherNonAssociatedAddress],
            mint: mint,
            ownerAccountId: owner
        )

        #expect(result == nonAssociatedAddress)
    }

    @Test
    func returnsNilForEmptyAddresses() {
        let result = SolanaTokenAccountSelector.preferredAccountAddress(
            from: [],
            mint: mint,
            ownerAccountId: owner
        )

        #expect(result == nil)
    }
}

private extension SolanaTokenAccountSelectorTests {
    func account(address: String, mint: String, balance: Decimal) -> SolanaTokenAccountInfoResponse {
        SolanaTokenAccountInfoResponse(address: address, mint: mint, balance: balance, space: 165)
    }

    func associatedTokenAddress(
        owner: String,
        mint: String,
        programId: PublicKey = .tokenProgramId
    ) throws -> String {
        let ownerKey = try #require(PublicKey(string: owner))
        let mintKey = try #require(PublicKey(string: mint))
        return try PublicKey.associatedTokenAddress(
            walletAddress: ownerKey,
            tokenMintAddress: mintKey,
            tokenProgramId: programId
        ).get().base58EncodedString
    }
}
