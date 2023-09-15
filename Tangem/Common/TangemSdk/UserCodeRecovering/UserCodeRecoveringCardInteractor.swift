//
//  UserCodeRecoveringCardInteractor.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk

class UserCodeRecoveringCardInteractor {
    private var cardInfo: CardInfo
    private let tangemSdk: TangemSdk
    private var _isUserCodeRecoveryAllowed: CurrentValueSubject<Bool, Never>

    init(with cardInfo: CardInfo) {
        self.cardInfo = cardInfo
        let config = UserWalletConfigFactory(cardInfo).makeConfig()
        tangemSdk = config.makeTangemSdk()
        _isUserCodeRecoveryAllowed = .init(cardInfo.card.userSettings.isUserCodeRecoveryAllowed)
    }
}

// MARK: - UserCodeRecovering

extension UserCodeRecoveringCardInteractor: UserCodeRecovering {
    var isUserCodeRecoveryAllowed: Bool {
        _isUserCodeRecoveryAllowed.value
    }

    var isUserCodeRecoveryAllowedPublisher: AnyPublisher<Bool, Never> {
        _isUserCodeRecoveryAllowed.eraseToAnyPublisher()
    }

    func toggleUserCodeRecoveryAllowed(completion: @escaping (Result<Bool, TangemSdkError>) -> Void) {
        let newValue = !_isUserCodeRecoveryAllowed.value

        tangemSdk.setUserCodeRecoveryAllowed(newValue, cardId: cardInfo.card.cardId) { [weak self] result in
            switch result {
            case .success:
                self?.cardInfo.card.userSettings.isUserCodeRecoveryAllowed = newValue
                self?._isUserCodeRecoveryAllowed.send(newValue)
                completion(.success(newValue))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
