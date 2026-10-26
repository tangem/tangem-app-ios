//
//  SuiProgrammableTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct SuiProgrammableTransactionBuilder {
    typealias Argument = SuiTransactionData.Argument

    private(set) var inputs: [SuiTransactionData.CallArg] = []
    private(set) var commands: [SuiTransactionData.Command] = []

    mutating func object(_ coin: SuiCoinObject) throws -> Argument {
        try input(.object(SuiTransactionData.ObjectRef(coin: coin)))
    }

    mutating func pure(_ value: UInt64) throws -> Argument {
        var encoder = SuiBCSEncoder()
        encoder.encode(value)
        return try input(.pure(encoder.data))
    }

    mutating func pure(_ address: SuiTransactionData.Address) throws -> Argument {
        try input(.pure(address.bytes))
    }

    mutating func redeemFunds(amount: UInt64, coinType: SuiCoinObject.CoinType) throws -> Argument {
        let typeTag = try SuiTransactionData.StructTag(coinType: coinType)
        let withdrawal = try input(.fundsWithdrawal(amount: amount, coinType: typeTag))

        let moveCall = SuiTransactionData.MoveCall(
            package: .framework,
            module: Constants.coinModule,
            function: Constants.redeemFundsFunction,
            typeArguments: [typeTag],
            arguments: [withdrawal]
        )

        return try .result(command(.moveCall(moveCall)))
    }

    mutating func mergeCoins(_ destination: Argument, _ sources: [Argument]) throws {
        guard !sources.isEmpty else {
            return
        }

        try command(.mergeCoins(destination, sources))
    }

    mutating func splitCoin(_ coin: Argument, amount: UInt64) throws -> Argument {
        let amountArgument = try pure(amount)
        let commandIndex = try command(.splitCoins(coin, [amountArgument]))
        return .nestedResult(commandIndex, 0)
    }

    mutating func transferObjects(_ objects: [Argument], to recipient: SuiTransactionData.Address) throws {
        let recipientArgument = try pure(recipient)
        try command(.transferObjects(objects, recipientArgument))
    }

    // MARK: - Private

    private mutating func input(_ callArg: SuiTransactionData.CallArg) throws -> Argument {
        let index = try makeIndex(count: inputs.count)
        inputs.append(callArg)
        return .input(index)
    }

    @discardableResult
    private mutating func command(_ command: SuiTransactionData.Command) throws -> UInt16 {
        let index = try makeIndex(count: commands.count)
        commands.append(command)
        return index
    }

    private func makeIndex(count: Int) throws -> UInt16 {
        guard let index = UInt16(exactly: count) else {
            throw BlockchainSdkError.failedToBuildTx
        }

        return index
    }
}

// MARK: - Constants

private extension SuiProgrammableTransactionBuilder {
    enum Constants {
        static let coinModule = "coin"
        static let redeemFundsFunction = "redeem_funds"
    }
}
