//
//  CardInteractor.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import Combine

protocol CardPreparable: AnyObject {
    func prepareCard(seed: Data?, completion: @escaping (Result<CardInfo, TangemSdkError>) -> Void)
}

protocol CardResettable: AnyObject {
    func resetCard(completion: @escaping (Result<Void, TangemSdkError>) -> Void)
}

class CardInteractor {
    private let tangemSdk: TangemSdk
    private var cardInfo: CardInfo
    private var commandBag: (any CardSessionRunnable)?
    private var cancellable: AnyCancellable?

    internal init(tangemSdk: TangemSdk, cardInfo: CardInfo) {
        self.tangemSdk = tangemSdk
        self.cardInfo = cardInfo
    }
}

extension CardInteractor: CardPreparable {
    func prepareCard(seed: Data?, completion: @escaping (Result<CardInfo, TangemSdkError>) -> Void) {
        let config = UserWalletConfigFactory(cardInfo).makeConfig()
        let task = PreparePrimaryCardTask(curves: config.mandatoryCurves, seed: seed)
        let initialMessage = Message(header: nil, body: Localization.initialMessageCreateWalletBody)
        commandBag = task

        cancellable = tangemSdk.startSessionPublisher(
            with: task,
            cardId: cardInfo.card.cardId,
            initialMessage: initialMessage
        )
        .combineLatest(NotificationCenter.didBecomeActivePublisher.mapError { $0.toTangemSdkError() }.mapVoid())
        .map { [cardInfo] response, _ -> CardInfo in
            var mutableCardInfo = cardInfo
            mutableCardInfo.card = CardDTO(card: response.card)
            mutableCardInfo.primaryCard = response.primaryCard
            return mutableCardInfo
        }
        .sink(receiveCompletion: { [weak self] completionResult in
            if case .failure(let error) = completionResult {
                completion(.failure(error))
            }

            self?.commandBag = nil
        }, receiveValue: { [weak self] newCardInfo in
            self?.cardInfo = newCardInfo
            completion(.success(newCardInfo))
        })
    }
}

extension CardInteractor: CardResettable {
    func resetCard(completion: @escaping (Result<Void, TangemSdkError>) -> Void) {
        let initialMessage = Message(header: nil, body: Localization.initialMessagePurgeWalletBody)
        let task = ResetToFactorySettingsTask()
        commandBag = task

        tangemSdk.startSession(
            with: task,
            cardId: cardInfo.card.cardId,
            initialMessage: initialMessage
        ) { [weak self] result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }

            self?.commandBag = nil
        }
    }
}
