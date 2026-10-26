//
//  SuiTransactionData.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct SuiTransactionData {
    let inputs: [CallArg]
    let commands: [Command]
    let sender: Address
    let gasData: GasData
    let expiration: Expiration

    func serialize() -> Data {
        var encoder = SuiBCSEncoder()
        encoder.encode(self)
        return encoder.data
    }
}

// MARK: - Models

extension SuiTransactionData {
    struct Address: Equatable {
        static let framework = Address(bytes: Data(repeating: 0, count: Constants.addressLength - 1) + [0x02])

        let bytes: Data

        init(_ hex: String) throws {
            let unprefixedHex = hex.removeHexPrefix()
            let hexLength = Constants.addressLength * 2

            guard !unprefixedHex.isEmpty, unprefixedHex.count <= hexLength else {
                throw BlockchainSdkError.failedToBuildTx
            }

            let bytes = Data(hexString: unprefixedHex.leftPadding(toLength: hexLength, withPad: "0"))

            guard bytes.count == Constants.addressLength else {
                throw BlockchainSdkError.failedToBuildTx
            }

            self.bytes = bytes
        }

        private init(bytes: Data) {
            self.bytes = bytes
        }
    }

    struct ObjectRef {
        let objectID: Address
        let version: UInt64
        let digest: Data

        init(coin: SuiCoinObject) throws {
            let digest = Base58.decode(coin.digest)

            guard digest.count == Constants.digestLength else {
                throw BlockchainSdkError.failedToBuildTx
            }

            objectID = try Address(coin.coinObjectId)
            version = coin.version
            self.digest = digest
        }
    }

    struct StructTag {
        let address: Address
        let module: String
        let name: String

        init(coinType: SuiCoinObject.CoinType) throws {
            address = try Address(coinType.contract)
            module = coinType.lowerID
            name = coinType.upperID
        }
    }

    enum CallArg {
        case pure(Data)
        case object(ObjectRef)
        case fundsWithdrawal(amount: UInt64, coinType: StructTag)
    }

    enum Argument: Equatable {
        case gasCoin
        case input(UInt16)
        case result(UInt16)
        case nestedResult(UInt16, UInt16)
    }

    struct MoveCall {
        let package: Address
        let module: String
        let function: String
        let typeArguments: [StructTag]
        let arguments: [Argument]
    }

    enum Command {
        case moveCall(MoveCall)
        case transferObjects([Argument], Argument)
        case splitCoins(Argument, [Argument])
        case mergeCoins(Argument, [Argument])
    }

    struct GasData {
        let payment: [ObjectRef]
        let owner: Address
        let price: UInt64
        let budget: UInt64
    }

    enum Expiration {
        case none
        case validDuring(minEpoch: UInt64, maxEpoch: UInt64, chainIdentifier: Data, nonce: UInt32)
    }
}

// MARK: - SuiBCSEncodable

extension SuiTransactionData: SuiBCSEncodable {
    func encode(to encoder: inout SuiBCSEncoder) {
        encoder.encodeVariant(Variant.transactionDataV1)
        encoder.encodeVariant(Variant.programmableTransaction)
        encoder.encode(inputs)
        encoder.encode(commands)
        encoder.encode(sender)
        encoder.encode(gasData)
        encoder.encode(expiration)
    }
}

extension SuiTransactionData.Address: SuiBCSEncodable {
    func encode(to encoder: inout SuiBCSEncoder) {
        encoder.encode(fixedBytes: bytes)
    }
}

extension SuiTransactionData.ObjectRef: SuiBCSEncodable {
    func encode(to encoder: inout SuiBCSEncoder) {
        encoder.encode(objectID)
        encoder.encode(version)
        encoder.encode(bytes: digest)
    }
}

extension SuiTransactionData.StructTag: SuiBCSEncodable {
    func encode(to encoder: inout SuiBCSEncoder) {
        encoder.encodeVariant(Variant.typeTagStruct)
        encoder.encode(address)
        encoder.encode(module)
        encoder.encode(name)
        encoder.encode([SuiTransactionData.StructTag]())
    }
}

extension SuiTransactionData.CallArg: SuiBCSEncodable {
    func encode(to encoder: inout SuiBCSEncoder) {
        switch self {
        case .pure(let bytes):
            encoder.encodeVariant(Variant.callArgPure)
            encoder.encode(bytes: bytes)

        case .object(let objectRef):
            encoder.encodeVariant(Variant.callArgObject)
            encoder.encodeVariant(Variant.objectArgImmOrOwned)
            encoder.encode(objectRef)

        case .fundsWithdrawal(let amount, let coinType):
            encoder.encodeVariant(Variant.callArgFundsWithdrawal)
            encoder.encodeVariant(Variant.reservationMaxAmountU64)
            encoder.encode(amount)
            encoder.encodeVariant(Variant.withdrawalTypeBalance)
            encoder.encode(coinType)
            encoder.encodeVariant(Variant.withdrawFromSender)
        }
    }
}

extension SuiTransactionData.Argument: SuiBCSEncodable {
    func encode(to encoder: inout SuiBCSEncoder) {
        switch self {
        case .gasCoin:
            encoder.encodeVariant(Variant.argumentGasCoin)

        case .input(let index):
            encoder.encodeVariant(Variant.argumentInput)
            encoder.encode(index)

        case .result(let index):
            encoder.encodeVariant(Variant.argumentResult)
            encoder.encode(index)

        case .nestedResult(let commandIndex, let resultIndex):
            encoder.encodeVariant(Variant.argumentNestedResult)
            encoder.encode(commandIndex)
            encoder.encode(resultIndex)
        }
    }
}

extension SuiTransactionData.MoveCall: SuiBCSEncodable {
    func encode(to encoder: inout SuiBCSEncoder) {
        encoder.encode(package)
        encoder.encode(module)
        encoder.encode(function)
        encoder.encode(typeArguments)
        encoder.encode(arguments)
    }
}

extension SuiTransactionData.Command: SuiBCSEncodable {
    func encode(to encoder: inout SuiBCSEncoder) {
        switch self {
        case .moveCall(let moveCall):
            encoder.encodeVariant(Variant.commandMoveCall)
            encoder.encode(moveCall)

        case .transferObjects(let objects, let address):
            encoder.encodeVariant(Variant.commandTransferObjects)
            encoder.encode(objects)
            encoder.encode(address)

        case .splitCoins(let coin, let amounts):
            encoder.encodeVariant(Variant.commandSplitCoins)
            encoder.encode(coin)
            encoder.encode(amounts)

        case .mergeCoins(let destination, let sources):
            encoder.encodeVariant(Variant.commandMergeCoins)
            encoder.encode(destination)
            encoder.encode(sources)
        }
    }
}

extension SuiTransactionData.GasData: SuiBCSEncodable {
    func encode(to encoder: inout SuiBCSEncoder) {
        encoder.encode(payment)
        encoder.encode(owner)
        encoder.encode(price)
        encoder.encode(budget)
    }
}

extension SuiTransactionData.Expiration: SuiBCSEncodable {
    func encode(to encoder: inout SuiBCSEncoder) {
        switch self {
        case .none:
            encoder.encodeVariant(Variant.expirationNone)

        case .validDuring(let minEpoch, let maxEpoch, let chainIdentifier, let nonce):
            encoder.encodeVariant(Variant.expirationValidDuring)
            encoder.encode(Optional(minEpoch))
            encoder.encode(Optional(maxEpoch))
            encoder.encode(UInt64?.none)
            encoder.encode(UInt64?.none)
            encoder.encode(bytes: chainIdentifier)
            encoder.encode(nonce)
        }
    }
}

// MARK: - Constants

private extension SuiTransactionData {
    enum Constants {
        static let addressLength = 32
        static let digestLength = 32
    }
}

private enum Variant {
    static let transactionDataV1 = 0
    static let programmableTransaction = 0
    static let callArgPure = 0
    static let callArgObject = 1
    static let callArgFundsWithdrawal = 2
    static let objectArgImmOrOwned = 0
    static let reservationMaxAmountU64 = 0
    static let withdrawalTypeBalance = 0
    static let withdrawFromSender = 0
    static let typeTagStruct = 7
    static let argumentGasCoin = 0
    static let argumentInput = 1
    static let argumentResult = 2
    static let argumentNestedResult = 3
    static let commandMoveCall = 0
    static let commandTransferObjects = 1
    static let commandSplitCoins = 2
    static let commandMergeCoins = 3
    static let expirationNone = 0
    static let expirationValidDuring = 2
}
