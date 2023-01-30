//
//  WalletConnectV2PersonalSignHandler.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import WalletConnectSwiftV2

struct WalletConnectV2PersonalSignHandler {
    private let message: [String]
    private let signer: WalletConnectSigner

    private var dataToSign: Data {
        Data(hex: message[0])
    }

    init(request: AnyCodable, using signer: WalletConnectSigner) throws {
        let castedParams: [String]
        do {
            castedParams = try request.get([String].self)
            if castedParams.count < 2 {
                throw WalletConnectV2Error.notEnoughDataInRequest(String(describing: request))
            }
        } catch {
            let stringRepresentation = request.stringRepresentation
            AppLog.shared.debug("[WC 2.0] Failed to create sign handler. Raised error: \(error), request data: \(stringRepresentation)")
            throw WalletConnectV2Error.dataInWrongFormat(stringRepresentation)
        }

        message = castedParams
        self.signer = signer
    }

    private func makePersonalMessageData(_ data: Data) -> Data {
        let prefix = "\u{19}Ethereum Signed Message:\n"
        let prefixData = (prefix + "\(data.count)").data(using: .utf8)!
        return prefixData + data
    }
}

extension WalletConnectV2PersonalSignHandler: WalletConnectMessageHandler {
    var event: WalletConnectEvent { .sign }

    func messageForUser(from dApp: WalletConnectSavedSession.DAppInfo) async throws -> String {
        let message = Localization.walletConnectPersonalSignMessage(dApp.name, dataToSign.hexString)
        return Localization.walletConnectAlertSignMessage(message)
    }

    func handle() async throws -> RPCResult {
        let personalMessageData = makePersonalMessageData(dataToSign)
        let hash = personalMessageData.sha3(.keccak256)
        do {
            let signedMessage = try await signer.sign(data: hash)
            return .response(AnyCodable(signedMessage))
        } catch {
            AppLog.shared.debug("[WC 2.0] Failed to sign message. \(error)")
            return .error(.internalError)
        }
    }
}
