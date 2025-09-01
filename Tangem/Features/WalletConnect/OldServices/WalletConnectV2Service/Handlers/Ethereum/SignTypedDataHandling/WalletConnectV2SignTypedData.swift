//
//  WalletConnectV2SignTypedData.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import enum BlockchainSdk.Blockchain
import struct Commons.AnyCodable
import enum JSONRPC.RPCResult

struct WalletConnectV2SignTypedDataHandler {
    private let message: String
    private let typedData: EIP712TypedData
    private let signer: WalletConnectSigner
    private let walletModel: any WalletModel
    private let request: AnyCodable

    init(
        requestParams: AnyCodable,
        blockchainId: String,
        signer: WalletConnectSigner,
        walletModelProvider: WalletConnectWalletModelProvider
    ) throws {
        let params = try requestParams.get([String].self)

        guard params.count >= 2 else {
            throw WalletConnectTransactionRequestProcessingError.notEnoughDataInRequest(requestParams.description)
        }

        message = params[1]

        let targetAddress = params[0]
        walletModel = try walletModelProvider.getModel(with: targetAddress, blockchainId: blockchainId)
        guard
            let messageData = message.data(using: .utf8),
            let typedData = try? JSONDecoder().decode(EIP712TypedData.self, from: messageData)
        else {
            throw WalletConnectTransactionRequestProcessingError.notEnoughDataInRequest(requestParams.description)
        }

        self.typedData = typedData
        self.signer = signer
        request = requestParams
    }
}

extension WalletConnectV2SignTypedDataHandler: WalletConnectMessageHandler {
    var method: WalletConnectMethod { .signTypedData }

    var requestData: Data {
        message.data(using: .utf8) ?? Data()
    }

    var rawTransaction: String? {
        request.stringRepresentation
    }

    var event: WalletConnectEvent { .sign }

    func messageForUser(from dApp: WalletConnectSavedSession.DAppInfo) async throws -> String {
        return Localization.walletConnectPersonalSignMessage(dApp.name, message)
    }

    func handle() async throws -> RPCResult {
        let hash = typedData.signHash

        let signedHash = try await signer.sign(data: hash, using: walletModel)
        return .response(AnyCodable(signedHash.hexString.addHexPrefix().lowercased()))
    }
}
