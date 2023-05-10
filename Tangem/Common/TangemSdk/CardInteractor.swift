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
    private var cardInfo: CardInfo?
    private var runnableBag: (any CardSessionRunnable)?
    private var cancellable: AnyCancellable?

    internal init(tangemSdk: TangemSdk, cardInfo: CardInfo) {
        self.tangemSdk = tangemSdk
        self.cardInfo = cardInfo
    }
}

extension CardInteractor: CardPreparable {
    func prepareCard(seed: Data?, completion: @escaping (Result<CardInfo, TangemSdkError>) -> Void) {
        guard let cardInfo else {
            completion(.failure(CardInteractionError.emptyCard.toTangemSdkError()))
            return
        }

        let config = UserWalletConfigFactory(cardInfo).makeConfig()
        let task = PreparePrimaryCardTask(curves: config.mandatoryCurves, seed: seed)
        let initialMessage = Message(header: nil, body: Localization.initialMessageCreateWalletBody)
        runnableBag = task

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

            self?.cancellable = nil
            self?.runnableBag = nil
        }, receiveValue: { [weak self] newCardInfo in
            self?.cardInfo = newCardInfo
            completion(.success(newCardInfo))
        })
    }
}

extension CardInteractor: CardResettable {
    func resetCard(completion: @escaping (Result<Void, TangemSdkError>) -> Void) {
        guard let cardInfo else {
            completion(.failure(CardInteractionError.emptyCard.toTangemSdkError()))
            return
        }

        let initialMessage = Message(header: nil, body: Localization.initialMessagePurgeWalletBody)
        let task = ResetToFactorySettingsTask()
        runnableBag = task

        tangemSdk.startSession(
            with: task,
            cardId: cardInfo.card.cardId,
            initialMessage: initialMessage
        ) { [weak self] result in
            switch result {
            case .success:
                self?.cardInfo = nil
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }

            self?.runnableBag = nil
        }
    }
}

extension CardInteractor {
    enum CardInteractionError: Error {
        case emptyCard
    }
}
