//
//  SignActivationOrderTask.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct SignedActivationOrder {
    let order: CardActivationOrder
    let signedOrderByCard: Data
    let cardAttestationSalt: Data
    let signedOrderByWallet: Data
}

class SignActivationOrderTask: CardSessionRunnable {
    typealias CompletionHandler = CompletionResult<SignedActivationOrder>

    private let orderToSign: CardActivationOrder
    private let isTestnet: Bool

    init(orderToSign: CardActivationOrder, isTestnet: Bool = false) {
        self.orderToSign = orderToSign
        self.isTestnet = isTestnet
    }

    func run(in session: CardSession, completion: @escaping CompletionHandler) {
        signOrderWithCard(in: session, completion: completion)
    }

    private func signOrderWithCard(in session: CardSession, completion: @escaping CompletionHandler) {
        let task = AttestCardKeyCommand(challenge: orderToSign.dataToSignByCard)
        task.run(in: session) { result in
            switch result {
            case .success(let attestResponse):
                self.signOrderWithWallet(
                    in: session,
                    signedOrderByCard: attestResponse,
                    completion: completion
                )
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func signOrderWithWallet(
        in session: CardSession,
        signedOrderByCard: AttestCardKeyResponse,
        completion: @escaping CompletionHandler
    ) {
        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }

        let visaUtilities = VisaUtilities(isTestnet: isTestnet)
        guard let derivationPath = visaUtilities.visaCardDerivationPath else {
            completion(.failure(.underlying(error: VisaActivationError.missingDerivationPath)))
            return
        }

        guard let wallet = card.wallets.first(where: { $0.curve == visaUtilities.mandatoryCurve }) else {
            completion(.failure(.underlying(error: VisaActivationError.missingWallet)))
            return
        }

        let signHashCommand = SignHashCommand(
            hash: orderToSign.dataToSignByWallet,
            walletPublicKey: wallet.publicKey,
            derivationPath: derivationPath
        )
        signHashCommand.run(in: session) { result in
            switch result {
            case .success(let signResponse):
                completion(.success(SignedActivationOrder(
                    order: self.orderToSign,
                    signedOrderByCard: signedOrderByCard.cardSignature,
                    cardAttestationSalt: signedOrderByCard.salt,
                    signedOrderByWallet: signResponse.signature
                )))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
