//
//  SendIntentValidatorTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import BlockchainSdk
@testable import Tangem

@Suite("Intent validator")
struct SendIntentValidatorTests {
    // MARK: - Send availability

    @Test("The wallet can send while it only lacks a balance or a fresh network state")
    func sendsWhenNothingBlocksTheWallet() {
        let statuses: [TokenActionAvailabilityProvider.SendActionAvailabilityStatus] = [
            .available,
            .zeroWalletBalance,
            .blockchainLoading,
            .blockchainUnreachable,
            .hasOnlyCachedBalance,
        ]

        for status in statuses {
            #expect(SendIntentValidator.canSend(status, hasBlockingPendingTransaction: false), "\(status)")
        }
    }

    @Test("The wallet can't send when the card, a pending transaction or the account blocks it")
    func doesNotSendWhenTheWalletIsBlocked() {
        let statuses: [TokenActionAvailabilityProvider.SendActionAvailabilityStatus] = [
            .oldCard,
            .cantSignLongTransactions,
            .hasPendingTransaction(blockchainDisplayName: "Ethereum"),
            .yieldModuleApproveNeeded,
            .noAccount,
        ]

        for status in statuses {
            #expect(!SendIntentValidator.canSend(status, hasBlockingPendingTransaction: false), "\(status)")
        }
    }

    @Test("A pending transaction blocks the send even while the balance is loading or only cached")
    func doesNotSendOverPendingTransaction() {
        let statuses: [TokenActionAvailabilityProvider.SendActionAvailabilityStatus] = [
            .available,
            .zeroWalletBalance,
            .blockchainLoading,
            .blockchainUnreachable,
            .hasOnlyCachedBalance,
        ]

        for status in statuses {
            #expect(!SendIntentValidator.canSend(status, hasBlockingPendingTransaction: true), "\(status)")
        }
    }

    // MARK: - Amount

    @Test("An amount fits the token when it has no more decimals than the token")
    func acceptsAmountWithinTokenDecimals() {
        let cases: [(amount: String, decimalCount: Int)] = [
            ("10", 6),
            ("10.123456", 6),
            ("1.50", 1),
            ("0.000000000000000001", 18),
            ("42", 0),
        ]

        for (amount, decimalCount) in cases {
            #expect(SendIntentValidator.fitsDecimals(Self.decimal(amount), decimalCount: decimalCount), "\(amount) with \(decimalCount) decimals")
        }
    }

    @Test("An amount with more decimals than the token is rejected")
    func rejectsAmountBeyondTokenDecimals() {
        let cases: [(amount: String, decimalCount: Int)] = [
            ("10.1234567", 6),
            ("0.0000000000000000001", 18),
            ("1.5", 0),
            ("0.00000001", 7),
        ]

        for (amount, decimalCount) in cases {
            #expect(!SendIntentValidator.fitsDecimals(Self.decimal(amount), decimalCount: decimalCount), "\(amount) with \(decimalCount) decimals")
        }
    }

    // MARK: - Own address

    @Test("The sender matches an own EVM address regardless of letter case and surrounding spaces")
    func matchesOwnEvmAddressLoosely() {
        let candidates = [
            Constants.ownEthereumAddress,
            Constants.ownEthereumAddress.uppercased().replacingOccurrences(of: "0X", with: "0x"),
            " \(Constants.ownEthereumAddress) ",
        ]

        for candidate in candidates {
            #expect(
                SendIntentValidator.isOwnAddress(candidate, ownAddresses: [Constants.ownEthereumAddress], blockchain: Constants.ethereum),
                "\(candidate)"
            )
        }
    }

    @Test("A foreign or empty sender is not an own address")
    func doesNotMatchForeignAddress() {
        for candidate in [Constants.foreignEthereumAddress, ""] {
            #expect(
                !SendIntentValidator.isOwnAddress(candidate, ownAddresses: [Constants.ownEthereumAddress], blockchain: Constants.ethereum),
                "\(candidate)"
            )
        }
    }

    // MARK: - Destination

    @Test("A valid foreign address of the network is a valid destination")
    func acceptsForeignAddress() {
        #expect(
            SendIntentValidator.isValidDestination(
                Constants.foreignEthereumAddress,
                ownAddresses: [Constants.ownEthereumAddress],
                blockchain: Constants.ethereum
            )
        )
        #expect(SendIntentValidator.isValidDestination(Constants.xrpAddress, ownAddresses: [], blockchain: Constants.xrp))
    }

    @Test("The sender's own address is never a destination, in any letter case")
    func rejectsOwnAddress() {
        for candidate in [Constants.ownEthereumAddress, Constants.ownEthereumAddress.uppercased().replacingOccurrences(of: "0X", with: "0x")] {
            #expect(
                !SendIntentValidator.isValidDestination(candidate, ownAddresses: [Constants.ownEthereumAddress], blockchain: Constants.ethereum),
                "\(candidate)"
            )
        }
    }

    @Test("A malformed, empty or other-network address is not a destination")
    func rejectsInvalidAddress() {
        let cases: [(address: String, blockchain: Blockchain)] = [
            ("not-an-address", Constants.ethereum),
            ("", Constants.ethereum),
            ("0x1111", Constants.ethereum),
            (Constants.xrpAddress, Constants.ethereum),
            (Constants.foreignEthereumAddress, Constants.xrp),
        ]

        for (address, blockchain) in cases {
            #expect(
                !SendIntentValidator.isValidDestination(address, ownAddresses: [Constants.ownEthereumAddress], blockchain: blockchain),
                "\(address) on \(blockchain.displayName)"
            )
        }
    }

    // MARK: - Memo

    @Test("A network without a memo field ignores whatever memo the intent carries")
    func ignoresMemoWithoutMemoField() {
        for memo in [nil, "", "12345", "any text"] {
            #expect(SendIntentValidator.isValidMemo(memo, for: Constants.ethereum), "\(String(describing: memo))")
        }
    }

    @Test("An XRP destination tag must be an unsigned 32-bit number, and a missing one is fine")
    func validatesXrpDestinationTag() {
        for memo in [nil, "", "0", "12345", "4294967295"] {
            #expect(SendIntentValidator.isValidMemo(memo, for: Constants.xrp), "\(String(describing: memo))")
        }

        for memo in ["abc", "-1", "4294967296", "1.5", "12 345"] {
            #expect(!SendIntentValidator.isValidMemo(memo, for: Constants.xrp), "\(memo)")
        }
    }

    @Test("A Stellar memo may be a number or text")
    func acceptsStellarTextMemo() {
        for memo in ["12345", "Pay for the coffee"] {
            #expect(SendIntentValidator.isValidMemo(memo, for: Constants.stellar), "\(memo)")
        }
    }
}

private extension SendIntentValidatorTests {
    static func decimal(_ value: String) -> Decimal {
        Decimal(string: value, locale: Locale(identifier: "en_US_POSIX"))!
    }

    enum Constants {
        static let ethereum = Blockchain.ethereum(testnet: false)
        static let xrp = Blockchain.xrp(curve: .secp256k1)
        static let stellar = Blockchain.stellar(curve: .ed25519_slip0010, testnet: false)
        static let ownEthereumAddress = "0xe34979ea46a0bb49f0e483f163c79be02101cd1b"
        static let foreignEthereumAddress = "0x1111111111111111111111111111111111111111"
        static let xrpAddress = "rHb9CJAWyB4rj91VRWn96DkukG4bwdtyTh"
    }
}
