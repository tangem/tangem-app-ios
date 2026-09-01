//
//  AccountModelsProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

protocol AccountModelsProvider {
    var accountModelsPublisher: AnyPublisher<[AccountModel], Never> { get }
}
