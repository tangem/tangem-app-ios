//
//  FactorySettingsResettingMock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

class FactorySettingsResettingMock: FactorySettingsResetting {
    func resetCard(headerMessage: String?, completion: @escaping (Result<Bool, TangemSdkError>) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            completion(.success(true))
        }
    }
}
