//
//  WalletConnectV2SignTypedData.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import WalletConnectSwiftV2

struct WalletConnectV2SignTypedDataHandler {
    private let message: String
    private let typedData: EIP712TypedData
    private let signer: WalletConnectSigner

    init(
        requestParams: AnyCodable,
        signer: WalletConnectSigner
    ) throws {
        let params = try requestParams.get([String].self)

        guard params.count >= 2 else {
            throw WalletConnectV2Error.notEnoughDataInRequest(requestParams.description)
        }

        message = params[1]

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
        Localization.walletConnectPersonalSignMessage(dApp.name, message)
    }

    func handle() async throws -> RPCResult {
        let hash = typedData.signHash

        let signedHash = try await signer.sign(data: hash)
        AppLog.shared.debug("[WC 2.0] Type data \(hash.hexString) signed: \(signedHash)")
        return .response(AnyCodable(signedHash))
    }
}
