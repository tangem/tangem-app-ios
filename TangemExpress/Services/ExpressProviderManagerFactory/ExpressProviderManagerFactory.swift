//
//  ExpressProviderManagerFactory.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

protocol ExpressProviderManagerFactory {
    func makeExpressProviderManager(provider: ExpressProvider) -> ExpressProviderManager?
}
