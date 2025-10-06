//
//  QuaiProtobufUtils.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
import WalletCore

/**
 * Simple utility to convert Ethereum transaction to Protobuf for Quai Network
 */
struct QuaiProtobufUtils {
    // MARK: - Public Methods

    /**
     * Converts Ethereum SigningInput to Protobuf format for Quai Network
     * Creates a Protobuf message with all required fields for Quai
     */
    func buildUnsignedProto(signingInput: EthereumSigningInput) -> Data {
        return buildCommonTransactionFields(signingInput: signingInput)
    }

    /**
     * Signed variant with V/R/S
     */
    func convertSigningInputToProtobuf(
        signingInput: EthereumSigningInput,
        vSignature: Data, // must be 1 byte: 0x00 or 0x01 (yParity)
        rSignature32: Data, // must be 32 bytes
        sSignature32: Data // must be 32 bytes
    ) -> Data {
        var result = buildCommonTransactionFields(signingInput: signingInput)
        result.append(encodeBytes(fieldNumber: Constants.field10AccessV, value: vSignature))
        result.append(encodeBytes(fieldNumber: Constants.field11AccessR, value: rSignature32))
        result.append(encodeBytes(fieldNumber: Constants.field12AccessS, value: sSignature32))
        return result
    }

    // MARK: - Private Methods

    private func buildCommonTransactionFields(signingInput: EthereumSigningInput) -> Data {
        var result = Data()

        result.append(encodeVarInt(fieldNumber: Constants.field1Type, value: UInt64(0)))

        let toAddress = Data(hexString: signingInput.toAddress)
        result.append(encodeBytes(fieldNumber: Constants.field2To, value: toAddress))

        let nonceValue = BigUInt(signingInput.nonce)
        result.append(encodeVarInt(fieldNumber: Constants.field3Nonce, value: nonceValue))

        let valueBytes = stripLeadingZeros(signingInput.transaction.contractGeneric.amount)
        result.append(encodeBytes(fieldNumber: Constants.field4Value, value: valueBytes))

        let gasValue = BigUInt(signingInput.gasLimit)
        result.append(encodeVarInt(fieldNumber: Constants.field5Gas, value: gasValue))

        result.append(encodeBytes(fieldNumber: Constants.field6Data, value: signingInput.transaction.contractGeneric.data))

        let chainIdBytes = stripLeadingZeros(signingInput.chainID)
        result.append(encodeBytes(fieldNumber: Constants.field7ChainId, value: chainIdBytes))

        let gasPriceBytesSigned = stripLeadingZeros(signingInput.gasPrice)
        result.append(encodeBytes(fieldNumber: Constants.field8GasPrice, value: gasPriceBytesSigned))

        result.append(encodeBytes(fieldNumber: Constants.field9AccessList, value: Data()))

        return result
    }

    private func encodeVarInt(fieldNumber: Int, value: UInt64) -> Data {
        let tag = (fieldNumber << 3) | 0
        var result = Data()
        result.append(encodeVarInt(UInt64(tag)))
        result.append(encodeVarInt(value))
        return result
    }

    private func encodeVarInt(fieldNumber: Int, value: BigUInt) -> Data {
        let tag = (fieldNumber << 3) | 0
        var result = Data()
        result.append(encodeVarInt(UInt64(tag)))
        result.append(encodeVarInt(value))
        return result
    }

    private func encodeBytes(fieldNumber: Int, value: Data) -> Data {
        let tag = (fieldNumber << 3) | 2
        var result = Data()
        result.append(encodeVarInt(UInt64(tag)))
        result.append(encodeVarInt(UInt64(value.count)))
        result.append(value)
        return result
    }

    private func encodeVarInt(_ value: UInt64) -> Data {
        var result = Data()
        var v = value
        while v >= 0x80 {
            result.append(UInt8(v | 0x80))
            v = v >> 7
        }
        result.append(UInt8(v))
        return result
    }

    private func encodeVarInt(_ value: BigUInt) -> Data {
        var result = Data()
        var v = value
        while v >= 0x80 {
            result.append(UInt8(v & 0xFF | 0x80))
            v = v >> 7
        }
        result.append(UInt8(v & 0xFF))
        return result
    }

    private func stripLeadingZeros(_ data: Data) -> Data {
        if data.isEmpty {
            return data
        }

        var start = 0
        while start < data.count - 1, data[start] == 0 {
            start += 1
        }

        return data.subdata(in: start ..< data.count)
    }
}

// MARK: - Constants Extension

extension QuaiProtobufUtils {
    enum Constants {
        static let field1Type = 1
        static let field2To = 2
        static let field3Nonce = 3
        static let field4Value = 4
        static let field5Gas = 5
        static let field6Data = 6
        static let field7ChainId = 7
        static let field8GasPrice = 8
        static let field9AccessList = 9
        static let field10AccessV = 10
        static let field11AccessR = 11
        static let field12AccessS = 12
    }
}
