//
//  MobileAccessCodeManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine

protocol MobileAccessCodeManager {
    var statePublisher: AnyPublisher<MobileAccessCodeState, Never> { get }
    func validate(accessCode: String)
    func cleanWrongAccessCodes()
}
