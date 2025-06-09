//
//  FactorySettingsResettingCardInteractor.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import TangemSdk

class FactorySettingsResettingCardInteractor {
    private let tangemSdk: TangemSdk
    private let filter: SessionFilter

    init(with cardInfo: CardInfo) {
        let config = UserWalletConfigFactory(cardInfo).makeConfig()
        tangemSdk = config.makeTangemSdk()
        filter = config.cardSessionFilter
    }

    init(with cardId: String) {
        tangemSdk = TangemSdkDefaultFactory().makeTangemSdk()
        filter = .cardId(cardId)
    }
}

// MARK: - FactorySettingsResetting

extension FactorySettingsResettingCardInteractor: FactorySettingsResetting {
    func resetCard(headerMessage: String? = nil, completion: @escaping (Result<Bool, TangemSdkError>) -> Void) {
        let initialMessage = Message(
            header: headerMessage,
            body: Localization.initialMessagePurgeWalletBody
        )

        let task = ResetToFactorySettingsTask()

        tangemSdk.startSession(
            with: task,
            filter: filter,
            initialMessage: initialMessage
        ) { result in
            // Fix alerts no-show
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                completion(result)
            }

            withExtendedLifetime(task) {}
        }
    }
}
