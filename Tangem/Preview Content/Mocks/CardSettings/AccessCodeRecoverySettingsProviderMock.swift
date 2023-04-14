//
//  AccessCodeRecoverySettingsProviderMock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

class AccessCodeRecoverySettingsProviderMock: AccessCodeRecoverySettingsProvider {
    private(set) var accessCodeRecoveryEnabled: Bool = true

    private var shouldShowError = false

    func setAccessCodeRecovery(to enabled: Bool, _ completionHandler: @escaping (Result<Void, TangemSdkError>) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            self.shouldShowError.toggle()
            if self.shouldShowError {
                completionHandler(.failure(.underlying(error: "Can't update access code recovery settings")))
            } else {
                self.accessCodeRecoveryEnabled = enabled
                completionHandler(.success(()))
            }
        }
    }
}
