//
//  WalletConnectV2PersonalSignHandler.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import CryptoSwift
import enum BlockchainSdk.Blockchain
import struct Commons.AnyCodable
import enum JSONRPC.RPCResult

struct WalletConnectV2PersonalSignHandler {
    private let message: String
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
        let castedParams: [String]
        do {
            castedParams = try request.get([String].self)
            if castedParams.count < 2 {
                throw WalletConnectV2Error.notEnoughDataInRequest(String(describing: request))
            }

            let targetAddress = castedParams[1]
            walletModel = try walletModelProvider.getModel(with: targetAddress, blockchainId: blockchainId)
            self.request = request
        } catch {
            let stringRepresentation = request.stringRepresentation
            WCLogger.error("Failed to create sign handler", error: error)
            throw WalletConnectV2Error.dataInWrongFormat(stringRepresentation)
        }

        message = castedParams[0]
        self.signer = signer
    }

    private func makePersonalMessageData(_ data: Data) -> Data {
        let prefix = "\u{19}Ethereum Signed Message:\n"
        let prefixData = (prefix + "\(data.count)").data(using: .utf8)!
        return prefixData + data
    }
}

extension WalletConnectV2PersonalSignHandler: WalletConnectMessageHandler {
    var method: WalletConnectMethod { .personalSign }

    var event: WalletConnectEvent { .sign }

    var requestData: Data {
        Data(hex: message)
    }

    var rawTransaction: String? {
        request.stringRepresentation
    }

    func messageForUser(from dApp: WalletConnectSavedSession.DAppInfo) async throws -> String {
        let message = Localization.walletConnectPersonalSignMessage(dApp.name, dataToSign.hexString)
        return Localization.walletConnectAlertSignMessage(message)
    }

    func handle() async throws -> RPCResult {
        let personalMessageData = makePersonalMessageData(dataToSign)
        let hash = personalMessageData.sha3(.keccak256)

        do {
            let signedMessage = try await signer.sign(data: hash, using: walletModel)
            return .response(AnyCodable(signedMessage.hexString.addHexPrefix().lowercased()))
        } catch {
            WCLogger.error("Failed to sign message", error: error)
            throw error
        }
    }
}
