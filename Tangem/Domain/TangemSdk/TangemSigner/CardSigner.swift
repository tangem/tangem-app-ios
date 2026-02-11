//
//  CardSigner.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk
import TangemLocalization
import BlockchainSdk

class CardSigner {
    private let initialMessage = Message(header: nil, body: Localization.initialMessageSignBody)
    private let filter: SessionFilter
    private let twinKey: TwinKey?
    private let sdk: TangemSdk
    private var _latestSignerType: TangemSignerType?

    init(filter: SessionFilter, sdk: TangemSdk, twinKey: TwinKey?) {
        self.filter = filter
        self.twinKey = twinKey
        self.sdk = sdk
    }

    private func updateLatestSignerType(card: Card) {
        let isRing = RingUtil().isRing(batchId: card.batchId)
        _latestSignerType = isRing ? TangemSignerType.ring : TangemSignerType.card
    }

    private func warnDeprecatedCards(card: Card) {
        for wallet in card.wallets {
            if let remainingSignatures = wallet.remainingSignatures, remainingSignatures <= 10 {
                let event = GeneralNotificationEvent.lowSignatures(count: remainingSignatures)

                if let message = event.description {
                    let alert = AlertBuilder.makeOkGotItAlertController(message: message)
                    AppPresenter.shared.show(alert)
                }

                return
            }
        }
    }
}

extension CardSigner: TangemSigner {
    var hasNFCInteraction: Bool { true }

    var latestSignerType: TangemSignerType? { _latestSignerType }

    func sign(hashes: [Data], walletPublicKey: Wallet.PublicKey) -> AnyPublisher<[SignatureInfo], any Error> {
        let dataToSign = SignData(
            derivationPath: walletPublicKey.derivationPath,
            hashes: hashes,
            publicKey: walletPublicKey.blockchainKey
        )

        return sign(dataToSign: [dataToSign], walletPublicKey: walletPublicKey)
    }

    func sign(dataToSign: [SignData], walletPublicKey: Wallet.PublicKey) -> AnyPublisher<[SignatureInfo], any Error> {
        let signCommand = MultipleSignTask(
            dataToSign: dataToSign,
            seedKey: walletPublicKey.seedKey,
            pairKey: twinKey?.getPairKey(for: walletPublicKey.seedKey)
        )

        return sdk.startSessionPublisher(with: signCommand, filter: filter, initialMessage: initialMessage)
            .handleEvents(
                receiveOutput: { [weak self] response in
                    if let lastResponse = response.last {
                        self?.updateLatestSignerType(card: lastResponse.card)
                        self?.warnDeprecatedCards(card: lastResponse.card)
                        TangemSdkAnalyticsLogger().logHealthIfNeeded(lastResponse.card)
                    }
                },
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        if !error.isCancellationError {
                            Analytics.logScanError(error, source: .sign)
                        }
                    }
                }
            )
            .map { responses in
                responses.flatMap { response in
                    zip(response.signatures, response.hashes).map { signature, hash in
                        SignatureInfo(signature: signature, publicKey: response.publicKey, hash: hash)
                    }
                }
            }
            .eraseError()
            .eraseToAnyPublisher()
    }

    func sign(hash: Data, walletPublicKey: Wallet.PublicKey) -> AnyPublisher<SignatureInfo, Error> {
        sign(hashes: [hash], walletPublicKey: walletPublicKey)
            .map { $0[0] }
            .eraseToAnyPublisher()
    }
}
