//
//  TangemProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Moya

class TangemProvider<Target: TargetType>: MoyaProvider<Target> {
    init(
        stubClosure: @escaping StubClosure = MoyaProvider.neverStub,
        plugins: [PluginType] = [],
        configuration: URLSessionConfiguration = .defaultConfiguration
    ) {
        let session = Session(configuration: configuration)

        super.init(stubClosure: stubClosure, session: session, plugins: plugins)
    }
}
