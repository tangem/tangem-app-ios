//
//  MoyaProviderBuilder.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemNetworkUtils

struct MoyaProviderBuilder {
    func buildProvider<T: TargetType>(configuration: URLSessionConfiguration) -> MoyaProvider<T> {
        let plugins: [PluginType] = [
            DeviceInfoPlugin(),
            TangemNetworkLoggerPlugin(logOptions: .verbose),
        ]

        return MoyaProvider<T>(session: Session(configuration: configuration), plugins: plugins)
    }
}
