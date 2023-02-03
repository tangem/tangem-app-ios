//
//  SignTypedDataHandler.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

/// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md

import Foundation
import WalletConnectSwift
import Combine
import TangemSdk
import BlockchainSdk

/// Some dApps sending version of sign typed data. This data are supported by our default data handler.
/// Soon we will need to migrate to WC 2.0 and we will need to update the WC pod to v2. I think WC protocols
/// in new version of framework already changed, so I guess no need to spend much time on refactoring our current solution
/// this small fix enough for now
/// [REDACTED_TODO_COMMENT]
class SignTypedDataHandlerV4: SignTypedDataHandler {
    override var action: WalletConnectAction { .signTypedDataV4 }
}

class SignTypedDataHandler: WalletConnectSignHandler {
    override var action: WalletConnectAction { .signTypedData }

    override func handle(request: Request) {
        do {
            let message = try request.parameter(of: String.self, at: 1)

            guard let session = dataSource?.session(for: request),
                  let messageData = message.data(using: .utf8),
                  let typedData = try? JSONDecoder().decode(EIP712TypedData.self, from: messageData) else {
                delegate?.send(.reject(request), for: action)
                return
            }

            let displayedMessage = Localization.walletConnectPersonalSignMessage(session.session.dAppInfo.peerMeta.name, message)
            askToSign(in: session, request: request, message: displayedMessage, dataToSign: typedData.signHash)
        } catch {
            delegate?.sendInvalid(request)
        }
    }

    override func signatureResponse(for signature: String, session: WalletConnectSession, request: Request) -> Response {
        .signature(signature, for: request)
    }

    override func sign(data: Data, walletPublicKey: Wallet.PublicKey, signer: TangemSigner) -> AnyPublisher<String, Error> {
        return signer.sign(hash: data, walletPublicKey: walletPublicKey)
            .tryMap { response -> String in
                if let unmarshalledSig = try? Secp256k1Signature(with: response).unmarshal(
                    with: walletPublicKey.blockchainKey,
                    hash: data
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
}
