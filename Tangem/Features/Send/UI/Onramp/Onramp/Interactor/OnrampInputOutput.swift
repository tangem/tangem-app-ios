//
//  OnrampInputOutput.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import TangemExpress

protocol OnrampInput: AnyObject {
    var isValidToRedirectPublisher: AnyPublisher<Bool, Never> { get }
}

protocol OnrampOutput: AnyObject {
    func userDidRequestOnramp(provider: OnrampProvider)
}
