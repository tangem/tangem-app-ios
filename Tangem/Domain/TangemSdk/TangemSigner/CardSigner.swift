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
import TangemFoundation

class CardSigner {
    private let initialMessage = Message(header: nil, body: Localization.initialMessageSignBody)
    private let filter: SessionFilter
    private let twinKey: TwinKey?
    private let sdkFactory: TangemSdkFactory
    private var _latestSignerType: TangemSignerType?

    init(filter: SessionFilter, sdkFactory: TangemSdkFactory, twinKey: TwinKey?) {
        self.filter = filter
        self.twinKey = twinKey
        self.sdkFactory = sdkFactory
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
    var latestSignerType: TangemSignerType? { _latestSignerType }

    func sign(hashes: [Data], walletPublicKey: Wallet.PublicKey) -> AnyPublisher<[SignatureInfo], any Error> {
        let dataToSign = SignData(
            derivationPath: walletPublicKey.derivationPath,
            hashes: hashes,
            publicKey: walletPublicKey.blockchainKey
        )

        return sign(dataToSign: [dataToSign], walletPublicKey: walletPublicKey)
    }

    func sign(walletPublicKey: Wallet.PublicKey, hashesProvider: @escaping () async throws -> [Data]) async throws -> [SignatureInfo] {
        let signCommand = MultipleSignTask(
            dataProvider: {
                let hashes = try await hashesProvider()
                return [SignData(derivationPath: walletPublicKey.derivationPath, hashes: hashes, publicKey: walletPublicKey.blockchainKey)]
            },
            seedKey: walletPublicKey.seedKey,
            pairKey: twinKey?.getPairKey(for: walletPublicKey.seedKey)
        )

        do {
            return try await sign(with: signCommand).async()
        } catch TangemSdkError.underlying(let error) {
            throw error
        }
    }

    func sign(dataToSign: [SignData], walletPublicKey: Wallet.PublicKey) -> AnyPublisher<[SignatureInfo], any Error> {
        let signCommand = MultipleSignTask(
            dataToSign: dataToSign,
            seedKey: walletPublicKey.seedKey,
            pairKey: twinKey?.getPairKey(for: walletPublicKey.seedKey)
        )

        return sign(with: signCommand)
    }

    private func sign(with signCommand: MultipleSignTask) -> AnyPublisher<[SignatureInfo], any Error> {
        let sdk = sdkFactory.makeTangemSdk()

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

                    withExtendedLifetime(sdk) {}
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
