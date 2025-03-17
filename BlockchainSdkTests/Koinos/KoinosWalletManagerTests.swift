//
//  KoinosWalletManagerTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
@testable import BlockchainSdk
import Testing

struct KoinosWalletManagerTests {
    private let walletManager: KoinosWalletManager

    init() {
        walletManager = KoinosWalletManager(
            wallet: Wallet(
                blockchain: .koinos(testnet: false),
                addresses: [
                    .default: PlainAddress(
                        value: "1AYz8RCnoafLnifMjJbgNb2aeW5CbZj8Tp",
                        publicKey: .init(seedKey: .init(), derivationType: nil),
                        type: .default
                    ),
                ]
            ),
            networkService: KoinosNetworkService(providers: []),
            transactionBuilder: KoinosTransactionBuilder(koinosNetworkParams: KoinosNetworkParams(isTestnet: false))
        )
    }

    @Test
    func txValidationSmoke() {
        walletManager.wallet.addBalance(balance: 100)
        walletManager.wallet.addMana(mana: 100)

        do {
            _ = try walletManager.validate(
                amount: .coinAmount(value: 10),
                fee: .manaFee(value: 0.3)
            )
        } catch {
            #expect(Bool(false), Comment(rawValue: "Unexpected error thrown: \(error)"))
        }
    }

    @Test
    func txValidationNotEnoughMana() {
        walletManager.wallet.addBalance(balance: 100)
        walletManager.wallet.addMana(mana: 0.2)

        do {
            try walletManager.validate(
                amount: .coinAmount(value: 10),
                fee: .manaFee(value: 0.3)
            )
            #expect(Bool(false), Comment(rawValue: "Expected ValidationError.insufficientFeeResource but no error was thrown"))
        } catch let e as ValidationError {
            #expect(
                e ==
                    ValidationError.insufficientFeeResource(
                        type: .mana,
                        current: 20000000,
                        max: 10000000000
                    )
            )
        } catch {
            #expect(Bool(false), Comment(rawValue: "Unexpected error thrown: \(error)"))
        }
    }

    @Test
    func txValidationAmountExceedsManaBalance() {
        walletManager.wallet.addBalance(balance: 100)
        walletManager.wallet.addMana(mana: 50)

        do {
            try walletManager.validate(
                amount: .coinAmount(value: 51),
                fee: .manaFee(value: 0.3)
            )
            #expect(Bool(false), Comment(rawValue: "Expected ValidationError.insufficientFeeResource but no error was thrown"))
        } catch let e as ValidationError {
            #expect(
                e ==
                    ValidationError.insufficientFeeResource(
                        type: .mana,
                        current: 50 * pow(10, 8),
                        max: 100 * pow(10, 8)
                    )
            )
        } catch {
            #expect(Bool(false), Comment(rawValue: "Unexpected error thrown: \(error)"))
        }
    }

    @Test
    func txValidationCoinBalanceDoesNotCoverFee() {
        walletManager.wallet.addBalance(balance: 0.2)
        walletManager.wallet.addMana(mana: 0.2)

        do {
            try walletManager.validate(
                amount: .coinAmount(value: 0.2),
                fee: .manaFee(value: 0.3)
            )
            #expect(Bool(false), Comment(rawValue: "Expected ValidationError.feeExceedsMaxFeeResource but no error was thrown"))
        } catch let e as ValidationError {
            #expect(e == ValidationError.feeExceedsMaxFeeResource)
        } catch {
            #expect(Bool(false), Comment(rawValue: "Unexpected error thrown: \(error)"))
        }
    }
}

private extension Amount {
    static let blockchain = Blockchain.koinos(testnet: false)

    static func coinAmount(value: Decimal) -> Amount {
        Amount(
            with: blockchain,
            type: .coin,
            value: value * pow(10, blockchain.decimalCount)
        )
    }

    static func manaAmount(value: Decimal) -> Amount {
        Amount(
            type: .feeResource(.mana),
            currencySymbol: FeeResourceType.mana.rawValue,
            value: value * pow(10, blockchain.decimalCount),
            decimals: blockchain.decimalCount
        )
    }
}

private extension Fee {
    static func manaFee(value: Decimal) -> Fee {
        Fee(.manaAmount(value: value))
    }
}

private extension Wallet {
    mutating func addBalance(balance: Decimal) {
        add(amount: .coinAmount(value: balance))
    }

    mutating func addMana(mana: Decimal) {
        add(
            amount: Amount(
                type: .feeResource(.mana),
                currencySymbol: FeeResourceType.mana.rawValue,
                value: mana * pow(10, blockchain.decimalCount),
                decimals: blockchain.decimalCount
            )
        )
    }
}
