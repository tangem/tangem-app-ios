//
//  CardScannerMock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt
import TangemSdk

class CardScannerMock: CardScanner {
    convenience init() {
        self.init(
            tangemSdk: TangemSdkDefaultFactory().makeTangemSdk(),
            parameters: .init(
                shouldAskForAccessCodes: false,
                performDerivations: false,
                sessionFilter: nil
            )
        )
    }

    required init(
        tangemSdk: TangemSdk,
        parameters: CardScannerParameters
    ) {}

    func scanCard(completion: @escaping (Result<AppScanTaskResponse, TangemSdkError>) -> Void) {}

    func scanCardPublisher() -> AnyPublisher<AppScanTaskResponse, TangemSdkError> {
        let response = AppScanTaskResponse(card: Card.walletV2, walletData: .none, primaryCard: nil)
        return Just(response)
            .setFailureType(to: TangemSdkError.self)
            .eraseToAnyPublisher()
    }
}
