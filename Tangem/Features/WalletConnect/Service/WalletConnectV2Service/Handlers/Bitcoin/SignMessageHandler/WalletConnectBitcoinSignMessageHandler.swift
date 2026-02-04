//
//  WalletConnectBitcoinSignMessageHandler.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import CryptoSwift
import enum BlockchainSdk.Blockchain
import struct Commons.AnyCodable
import enum JSONRPC.RPCResult

struct WalletConnectBitcoinSignMessageHandler {
    private let message: String
    private let address: String
    private let signer: WalletConnectSigner
    private let walletModel: any WalletModel
    private let request: AnyCodable

    private var dataToSign: Data {
        let hexData = Data(hex: message)
        // If received message is not a hex string, then convert it to bytes
        if hexData.isEmpty, !message.hasHexPrefix() {
            return message.data(using: .utf8) ?? Data()
        } else {
            return hexData
        }
    }

    init(
        request: AnyCodable,
        blockchainId: String,
        signer: WalletConnectSigner,
        walletModelProvider: WalletConnectWalletModelProvider
    ) throws {
        let castedParams: WalletConnectBtcSignMessageRequest
        do {
            castedParams = try request.get(WalletConnectBtcSignMessageRequest.self)

            let targetAddress = castedParams.address
            walletModel = try walletModelProvider.getModel(with: targetAddress, blockchainId: blockchainId)
            self.request = request
        } catch {
            let stringRepresentation = request.stringRepresentation
            WCLogger.error("Failed to create sign handler", error: error)
            throw WalletConnectTransactionRequestProcessingError.invalidPayload(stringRepresentation)
        }

        address = castedParams.address
        message = castedParams.message
        self.signer = signer
    }

    init(
        request: AnyCodable,
        blockchainId: String,
        signer: WalletConnectSigner,
        wcAccountsWalletModelProvider: WalletConnectAccountsWalletModelProvider,
        accountId: String
    ) throws {
        let castedParams: WalletConnectBtcSignMessageRequest
        do {
            castedParams = try request.get(WalletConnectBtcSignMessageRequest.self)

            let targetAddress = castedParams.address
            walletModel = try wcAccountsWalletModelProvider.getModel(
                with: targetAddress,
                blockchainId: blockchainId,
                accountId: accountId
            )

            self.request = request
        } catch {
            let stringRepresentation = request.stringRepresentation
            WCLogger.error("Failed to create sign handler", error: error)
            throw WalletConnectTransactionRequestProcessingError.invalidPayload(stringRepresentation)
        }

        address = castedParams.address
        message = castedParams.message
        self.signer = signer
    }

    private func makePersonalMessageData(_ message: Data) -> Data {
        // 0x18 + "Bitcoin Signed Message:\n"
        let prefix = "\u{18}Bitcoin Signed Message:\n"
        var result = Data()

        // Prefix (already includes 0x18 length for the magic string)
        result.append(prefix.data(using: .utf8)!)

        // Append compactSize(message.count)
        result.append(compactSize(of: message.count))

        // Append the actual message bytes
        result.append(message)

        return result
    }

    /// Bitcoin compactSize (varint) encoding for the length
    private func compactSize(of length: Int) -> Data {
        if length < 0xFD {
            // 1-byte length
            return Data([UInt8(length)])
        } else if length <= 0xFFFF {
            var value = UInt16(length).littleEndian
            return Data([0xFD]) + withUnsafeBytes(of: &value) { Data($0) }
        } else if length <= 0xFFFF_FFFF {
            var value = UInt32(length).littleEndian
            return Data([0xFE]) + withUnsafeBytes(of: &value) { Data($0) }
        } else {
            var value = UInt64(length).littleEndian
            return Data([0xFF]) + withUnsafeBytes(of: &value) { Data($0) }
        }
    }
}

extension WalletConnectBitcoinSignMessageHandler: WalletConnectMessageHandler {
    var method: WalletConnectMethod { .signMessage }

    var requestData: Data {
        Data(message.utf8)
    }

    var rawTransaction: String? {
        request.stringRepresentation
    }

    func validate() async throws -> WalletConnectMessageHandleRestrictionType {
        .empty
    }

    func handle() async throws -> RPCResult {
        let personalMessageData = makePersonalMessageData(dataToSign)
        let hash = personalMessageData.sha256().sha256()

        do {
            // Delegate signature formatting to Bitcoin-specific signer
            let btcSignature = try await signer.sign(data: hash, using: walletModel)
            let response = WalletConnectBtcSignMessageResponse(
                address: address,
                signature: btcSignature.hexString.lowercased()
            )
            return .response(AnyCodable(response))
        } catch {
            WCLogger.error("Failed to sign message", error: error)
            throw error
        }
    }
}

struct WalletConnectBtcSignMessageRequest: Codable {
    let address: String
    let message: String
}

struct WalletConnectBtcSignMessageResponse: Codable {
    let address: String
    let signature: String
}
