//
//  HotAccessCodeManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine

protocol HotAccessCodeManager: AnyObject {
    var statePublisher: AnyPublisher<HotAccessCodeState, Never> { get }
    func validate(accessCode: String) throws
}
