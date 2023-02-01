//
//  WalletConnectV2SignTypedData.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import enum BlockchainSdk.Blockchain
import struct WalletConnectSwiftV2.AnyCodable
import enum WalletConnectSwiftV2.RPCResult

struct WalletConnectV2SignTypedDataHandler {
    private let message: String
    private let typedData: EIP712TypedData
    private let signer: WalletConnectSigner
    private let walletModel: WalletModel

    init(
        requestParams: AnyCodable,
        blockchain: Blockchain,
        signer: WalletConnectSigner,
        walletModelProvider: WalletConnectV2WalletModelProvider
    ) throws {
        let params = try requestParams.get([String].self)

        guard params.count >= 2 else {
            throw WalletConnectV2Error.notEnoughDataInRequest(requestParams.description)
        }

        message = params[1]

        let targetAddress = params[0]
        walletModel = try walletModelProvider.getModel(with: targetAddress, in: blockchain)
        guard
            let messageData = message.data(using: .utf8),
            let typedData = try? JSONDecoder().decode(EIP712TypedData.self, from: messageData)
        else {
            throw WalletConnectV2Error.notEnoughDataInRequest(requestParams.description)
        }

        self.typedData = typedData
        self.signer = signer
    }
}

extension WalletConnectV2SignTypedDataHandler: WalletConnectMessageHandler {
    var event: WalletConnectEvent { .sign }

    func messageForUser(from dApp: WalletConnectSavedSession.DAppInfo) async throws -> String {
        return Localization.walletConnectPersonalSignMessage(dApp.name, message)
    }

    func handle() async throws -> RPCResult {
        let hash = typedData.signHash

        let signedHash = try await signer.sign(data: hash, using: walletModel)
        AppLog.shared.debug("[WC 2.0] Type data \(hash.hexString) signed: \(signedHash)")
        return .response(AnyCodable(signedHash))
    }
}
