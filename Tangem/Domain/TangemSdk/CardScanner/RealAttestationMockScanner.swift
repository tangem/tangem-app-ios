//
//  RealAttestationMockScanner.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt
import TangemSdk
import TangemFoundation
import TangemNetworkUtils

class RealAttestationMockScanner: CardScanner {
    private let commonScanner: CommonCardScanner
    private var cancellable: AnyCancellable?

    init() {
        commonScanner = CommonCardScanner()
    }

    func scanCardPublisher() -> AnyPublisher<AppScanTaskResponse, TangemSdkError> {
        return commonScanner.scanCardPublisher()
    }

    func scanCard(completion: @escaping (Result<AppScanTaskResponse, TangemSdkError>) -> Void) {
        commonScanner.scanCard(completion: completion)
    }
}
