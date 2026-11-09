//
//  ClearAppAttestationStatusUseCase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct TangemLogger.Logger

package struct ClearAppAttestationStatusUseCase: Sendable {
    private let appAttestationStatusRepository: any AppAttestationStatusRepository

    init(appAttestationStatusRepository: some AppAttestationStatusRepository) {
        self.appAttestationStatusRepository = appAttestationStatusRepository
    }

    package func callAsFunction() {
        appAttestationStatusRepository.persist(isAppAttested: false)
    }
}
