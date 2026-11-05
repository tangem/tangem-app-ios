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
            #expect(SendMCPIntentValidator.fitsDecimals(Self.decimal(amount), decimalCount: decimalCount), "\(amount) with \(decimalCount) decimals")
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
            #expect(!SendMCPIntentValidator.fitsDecimals(Self.decimal(amount), decimalCount: decimalCount), "\(amount) with \(decimalCount) decimals")
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
                SendMCPIntentValidator.isOwnAddress(candidate, ownAddresses: [Constants.ownEthereumAddress], blockchain: Constants.ethereum),
                "\(candidate)"
            )
        }
    }

    @Test("A foreign or empty sender is not an own address")
    func doesNotMatchForeignAddress() {
        for candidate in [Constants.foreignEthereumAddress, ""] {
            #expect(
                !SendMCPIntentValidator.isOwnAddress(candidate, ownAddresses: [Constants.ownEthereumAddress], blockchain: Constants.ethereum),
                "\(candidate)"
            )
        }
    }

    // MARK: - Destination

    @Test("A valid foreign address of the network is a valid destination")
    func acceptsForeignAddress() {
        #expect(
            SendMCPIntentValidator.isValidDestination(
                Constants.foreignEthereumAddress,
                ownAddresses: [Constants.ownEthereumAddress],
                blockchain: Constants.ethereum
            )
        )
        #expect(SendMCPIntentValidator.isValidDestination(Constants.xrpAddress, ownAddresses: [], blockchain: Constants.xrp))
    }

    @Test("The sender's own address is never a destination, in any letter case")
    func rejectsOwnAddress() {
        for candidate in [Constants.ownEthereumAddress, Constants.ownEthereumAddress.uppercased().replacingOccurrences(of: "0X", with: "0x")] {
            #expect(
                !SendMCPIntentValidator.isValidDestination(candidate, ownAddresses: [Constants.ownEthereumAddress], blockchain: Constants.ethereum),
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
                !SendMCPIntentValidator.isValidDestination(address, ownAddresses: [Constants.ownEthereumAddress], blockchain: blockchain),
                "\(address) on \(blockchain.displayName)"
            )
        }
    }

    // MARK: - Memo

    @Test("A network without a memo field ignores whatever memo the intent carries")
    func ignoresMemoWithoutMemoField() {
        for memo in [nil, "", "12345", "any text"] {
            #expect(SendMCPIntentValidator.isValidMemo(memo, for: Constants.ethereum), "\(String(describing: memo))")
        }
    }

    @Test("An XRP destination tag must be an unsigned 32-bit number, and a missing one is fine")
    func validatesXrpDestinationTag() {
        for memo in [nil, "", "0", "12345", "4294967295"] {
            #expect(SendMCPIntentValidator.isValidMemo(memo, for: Constants.xrp), "\(String(describing: memo))")
        }

        for memo in ["abc", "-1", "4294967296", "1.5", "12 345"] {
            #expect(!SendMCPIntentValidator.isValidMemo(memo, for: Constants.xrp), "\(memo)")
        }
    }

    @Test("A Stellar memo may be a number or text")
    func acceptsStellarTextMemo() {
        for memo in ["12345", "Pay for the coffee"] {
            #expect(SendMCPIntentValidator.isValidMemo(memo, for: Constants.stellar), "\(memo)")
        }
    }

    // MARK: - Modification

    @Test("A transfer sent as the intent asked leaves it unmodified", arguments: [
        (Self.intent(), Self.transfer()),
        (Self.intent(), Self.transfer(destination: Constants.checksummedDestinationAddress)),
        (Self.intent(memo: "invoice 42"), Self.transfer(memo: nil)),
        (Self.intent(network: .xrp, memo: "12345"), Self.transfer(network: .xrp, memo: "12345")),
        (Self.intent(network: .xrp, memo: nil), Self.transfer(network: .xrp, memo: "")),
    ])
    func transferAsAskedIsNotModified(intent: SendMCPIntent, transfer: TransactionDispatcherResult.Transfer) throws {
        let blockchain = try #require(Network(rawValue: intent.networkID)).blockchain

        #expect(!SendMCPIntentValidator.isModified(intent, sentAs: transfer, blockchain: blockchain))
    }

    @Test("A changed amount, recipient or memo modifies the intent", arguments: [
        (Self.intent(amount: "1"), Self.transfer(amount: "0.99979")),
        (Self.intent(), Self.transfer(destination: Constants.foreignEthereumAddress)),
        (Self.intent(network: .xrp, memo: "12345"), Self.transfer(network: .xrp, memo: "54321")),
        (Self.intent(network: .xrp, memo: nil), Self.transfer(network: .xrp, memo: "12345")),
        (Self.intent(network: .xrp, memo: "12345"), Self.transfer(network: .xrp, memo: nil)),
    ])
    func changedTransferIsModified(intent: SendMCPIntent, transfer: TransactionDispatcherResult.Transfer) throws {
        let blockchain = try #require(Network(rawValue: intent.networkID)).blockchain

        #expect(SendMCPIntentValidator.isModified(intent, sentAs: transfer, blockchain: blockchain))
    }

    @Test("A send that was no plain transfer modifies the intent")
    func sendWithoutTransferIsModified() {
        #expect(SendMCPIntentValidator.isModified(Self.intent(), sentAs: nil, blockchain: Constants.ethereum))
    }
}

private extension SendIntentValidatorTests {
    static func decimal(_ value: String) -> Decimal {
        Decimal(string: value, locale: Locale(identifier: "en_US_POSIX"))!
    }

    static func intent(network: Network = .ethereum, amount: String = "1", memo: String? = nil) -> SendMCPIntent {
        SendMCPIntent(
            id: "intent",
            networkID: network.rawValue,
            tokenID: network.rawValue,
            fromAddress: Constants.ownEthereumAddress,
            toAddress: network.destinationAddress,
            amount: decimal(amount),
            memo: memo,
            isCompleted: false,
            agentID: "agent"
        )
    }

    static func transfer(
        network: Network = .ethereum,
        amount: String = "1",
        destination: String? = nil,
        memo: String? = nil
    ) -> TransactionDispatcherResult.Transfer {
        TransactionDispatcherResult.Transfer(amount: decimal(amount), destination: destination ?? network.destinationAddress, memo: memo)
    }

    enum Network: String {
        case ethereum
        case xrp

        var blockchain: Blockchain {
            switch self {
            case .ethereum: Constants.ethereum
            case .xrp: Constants.xrp
            }
        }

        var destinationAddress: String {
            switch self {
            case .ethereum: Constants.destinationAddress
            case .xrp: Constants.xrpAddress
            }
        }
    }

    enum Constants {
        static let ethereum = Blockchain.ethereum(testnet: false)
        static let xrp = Blockchain.xrp(curve: .secp256k1)
        static let stellar = Blockchain.stellar(curve: .ed25519_slip0010, testnet: false)
        static let ownEthereumAddress = "0xe34979ea46a0bb49f0e483f163c79be02101cd1b"
        static let foreignEthereumAddress = "0x1111111111111111111111111111111111111111"
        static let destinationAddress = "0x5aaeb6053f3e94c9b9a09f33669435e7ef1beaed"
        static let checksummedDestinationAddress = "0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed"
        static let xrpAddress = "rHb9CJAWyB4rj91VRWn96DkukG4bwdtyTh"
    }
}
