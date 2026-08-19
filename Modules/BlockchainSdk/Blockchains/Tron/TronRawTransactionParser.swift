//
//  TronRawTransactionParser.swift
//  BlockchainSdk
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

/// Lifts the payload out of a provider-built `Transaction.raw` protobuf.
/// The embedded block reference and expiration are discarded — provider transactions expire
/// within about a minute, so the wallet rebuilds against a fresh block.
public struct TronRawTransactionParser {
    public enum ParsedTransaction {
        case contractCall(ContractCall)
        case transfer(Transfer)
    }

    public struct ContractCall {
        public let ownerAddress: String
        public let contractAddress: String
        public let callData: Data
        /// In sun.
        public let callValue: Int64
        /// In sun; `nil` when the transaction doesn't set one.
        public let feeLimit: Int64?
        /// From the transaction-level `raw.data` field.
        public let memo: String?
    }

    public struct Transfer {
        public let ownerAddress: String
        public let destinationAddress: String
        /// In sun.
        public let amount: Int64
        /// From the transaction-level `raw.data` field.
        public let memo: String?
    }

    public init() {}

    public func parse(rawTransaction: Data) throws -> ParsedTransaction {
        let raw: Protocol_Transaction.raw

        do {
            raw = try Protocol_Transaction.raw(serializedBytes: rawTransaction)
        } catch {
            throw TronRawTransactionParserError.invalidRawTransaction
        }

        guard raw.contract.count == 1, let contract = raw.contract.first else {
            throw TronRawTransactionParserError.unexpectedContractCount
        }

        let memo = raw.data.isEmpty ? nil : String(data: raw.data, encoding: .utf8)

        switch contract.type {
        case .triggerSmartContract:
            let call: Protocol_TriggerSmartContract
            do {
                call = try Protocol_TriggerSmartContract(unpackingAny: contract.parameter)
            } catch {
                throw TronRawTransactionParserError.invalidRawTransaction
            }

            guard !call.data.isEmpty else {
                throw TronRawTransactionParserError.callDataNotFound
            }

            return .contractCall(
                ContractCall(
                    ownerAddress: call.ownerAddress.base58CheckEncodedString,
                    contractAddress: call.contractAddress.base58CheckEncodedString,
                    callData: call.data,
                    callValue: call.callValue,
                    feeLimit: raw.feeLimit > 0 ? raw.feeLimit : nil,
                    memo: memo
                )
            )

        case .transferContract:
            let transfer: Protocol_TransferContract
            do {
                transfer = try Protocol_TransferContract(unpackingAny: contract.parameter)
            } catch {
                throw TronRawTransactionParserError.invalidRawTransaction
            }

            return .transfer(
                Transfer(
                    ownerAddress: transfer.ownerAddress.base58CheckEncodedString,
                    destinationAddress: transfer.toAddress.base58CheckEncodedString,
                    amount: transfer.amount,
                    memo: memo
                )
            )

        default:
            throw TronRawTransactionParserError.unsupportedContractType
        }
    }
}

public enum TronRawTransactionParserError: String, Hashable, LocalizedError {
    case invalidRawTransaction
    case unexpectedContractCount
    case unsupportedContractType
    case callDataNotFound

    public var errorDescription: String? {
        switch self {
        case .invalidRawTransaction: "The data is not a valid raw Tron transaction."
        case .unexpectedContractCount: "The raw transaction doesn't contain exactly one contract."
        case .unsupportedContractType: "The raw transaction is not a smart-contract call or a transfer."
        case .callDataNotFound: "The raw transaction carries no calldata."
        }
    }
}
