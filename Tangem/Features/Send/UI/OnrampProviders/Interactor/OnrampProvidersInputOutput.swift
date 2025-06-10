//
//  OnrampProvidersInputOutput.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import TangemExpress
import TangemFoundation

protocol OnrampProvidersInput: AnyObject {
    var selectedOnrampProvider: OnrampProvider? { get }
    var selectedOnrampProviderPublisher: AnyPublisher<LoadingResult<OnrampProvider, Never>?, Never> { get }

    var onrampProvidersPublisher: AnyPublisher<LoadingResult<ProvidersList, Error>?, Never> { get }
}

protocol OnrampProvidersOutput: AnyObject {
    func userDidSelect(provider: OnrampProvider)
}
