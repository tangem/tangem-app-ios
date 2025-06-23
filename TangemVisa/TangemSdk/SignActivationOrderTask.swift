//
//  SignActivationOrderTask.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

public struct SignedActivationOrder {
    public let cardSignedOrder: Card
    public let order: VisaCardAcceptanceOrderInfo
    public let signedOrderByWallet: Data
}

/// Task for signing activation order using derived key
final class SignActivationOrderTask: CardSessionRunnable {
    typealias CompletionHandler = CompletionResult<SignedActivationOrder>

    private let orderToSign: VisaCardAcceptanceOrderInfo
    private let isTestnet: Bool
    private let visaUtilities: VisaUtilities

    init(orderToSign: VisaCardAcceptanceOrderInfo, isTestnet: Bool) {
        self.orderToSign = orderToSign
        self.isTestnet = isTestnet
        visaUtilities = VisaUtilities(isTestnet: isTestnet)
    }

    func run(in session: CardSession, completion: @escaping CompletionHandler) {
        signOrderWithWallet(in: session, completion: completion)
    }

    private func signOrderWithWallet(
        in session: CardSession,
        completion: @escaping CompletionHandler
    ) {
        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }

        guard let wallet = card.wallets.first(where: { $0.curve == visaUtilities.mandatoryCurve }) else {
            completion(.failure(.underlying(error: VisaActivationError.missingWallet)))
            return
        }

        let signHashCommand = SignHashCommand(
            hash: orderToSign.hashToSignByWallet,
            walletPublicKey: wallet.publicKey
        )
        signHashCommand.run(in: session) { result in
            switch result {
            case .success(let signResponse):
                do {
                    let processor = VisaAcceptanceSignatureProcessor()
                    let processedSignature = try processor.processAcceptanceSignature(
                        signature: signResponse.signature,
                        walletPublicKey: wallet.publicKey,
                        originHash: self.orderToSign.hashToSignByWallet
                    )

                    completion(.success(SignedActivationOrder(
                        cardSignedOrder: card,
                        order: self.orderToSign,
                        signedOrderByWallet: processedSignature
                    )))
                } catch {
                    completion(.failure(.underlying(error: error)))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
