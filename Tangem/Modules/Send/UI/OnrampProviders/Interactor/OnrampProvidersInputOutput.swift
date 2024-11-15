//
//  OnrampProvidersInputOutput.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import TangemExpress

protocol OnrampProvidersInput: AnyObject {
    var selectedOnrampProvider: OnrampProvider? { get }
    var selectedOnrampProviderPublisher: AnyPublisher<LoadingValue<OnrampProvider>?, Never> { get }

    var onrampProvidersPublisher: AnyPublisher<LoadingValue<ProvidersList>, Never> { get }
}

protocol OnrampProvidersOutput: AnyObject {
    func userDidSelect(provider: OnrampProvider)
}
