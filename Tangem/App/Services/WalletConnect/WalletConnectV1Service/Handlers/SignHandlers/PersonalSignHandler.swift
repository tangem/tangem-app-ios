//
//  PersonalSignHandler.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import WalletConnectSwift
import Combine
import TangemSdk
import BlockchainSdk

class PersonalSignHandler: WalletConnectSignHandler {
    override var action: WalletConnectAction { .personalSign }

    override func handle(request: Request) {
        do {
            let messageBytes = try request.parameter(of: String.self, at: 0)

            guard let session = dataSource?.session(for: request) else {
                delegate?.send(.reject(request), for: action)
                return
            }

            let messageData = Data(hex: messageBytes)
            let displayedMessage = Localization.walletConnectPersonalSignMessage(session.session.dAppInfo.peerMeta.name, messageBytes)
            let personalMessageData = makePersonalMessageData(messageData)

            askToSign(in: session, request: request, message: displayedMessage, dataToSign: personalMessageData)
        } catch {
            delegate?.sendInvalid(request)
        }
    }

    override func signatureResponse(for signature: String, session: WalletConnectSession, request: Request) -> Response {
        .signature(signature, for: request)
    }

    override func sign(data: Data, walletPublicKey: Wallet.PublicKey, signer: TangemSigner) -> AnyPublisher<String, Error> {
        let hash = data.sha3(.keccak256)

        return signer.sign(hash: hash, walletPublicKey: walletPublicKey)
            .tryMap { response -> String in
                if let unmarshalledSig = try? Secp256k1Signature(with: response).unmarshal(
                    with: walletPublicKey.blockchainKey,
                    hash: hash
                ) {
                    let strSig = "0x" + unmarshalledSig.r.hexString + unmarshalledSig.s.hexString +
                        unmarshalledSig.v.hexString
                    return strSig
                } else {
                    throw WalletConnectServiceError.signFailed
                }
            }
            .eraseToAnyPublisher()
    }

    private func makePersonalMessageData(_ data: Data) -> Data {
        let prefix = "\u{19}Ethereum Signed Message:\n"
        let prefixData = (prefix + "\(data.count)").data(using: .utf8)!
        return prefixData + data
    }
}
