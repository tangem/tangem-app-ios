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

protocol CardResettable: AnyObject {
    func resetCard(completion: @escaping (Result<Void, TangemSdkError>) -> Void)
}

class CardInteractor {
    private let tangemSdk: TangemSdk
    private var cardId: String
    private var runnableBag: (any CardSessionRunnable)?
    private var cancellable: AnyCancellable?

    internal init(tangemSdk: TangemSdk, cardId: String) {
        self.tangemSdk = tangemSdk
        self.cardId = cardId
    }
}

// MARK: - CardResettable

extension CardInteractor: CardResettable {
    func resetCard(completion: @escaping (Result<Void, TangemSdkError>) -> Void) {
        let initialMessage = Message(header: nil, body: Localization.initialMessagePurgeWalletBody)
        let task = ResetToFactorySettingsTask()
        runnableBag = task

        tangemSdk.startSession(
            with: task,
            cardId: cardId,
            initialMessage: initialMessage
        ) { [weak self] result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }

            self?.runnableBag = nil
        }
    }
}
