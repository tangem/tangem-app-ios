//
//  ExpressDependenciesFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemExpress

protocol ExpressDependenciesFactory {
    var expressInteractor: ExpressInteractor { get }
    var expressAPIProvider: ExpressAPIProvider { get }
    var expressRepository: ExpressRepository { get }
}
