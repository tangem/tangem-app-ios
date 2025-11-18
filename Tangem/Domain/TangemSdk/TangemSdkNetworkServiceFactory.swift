//
//  TangemSdkNetworkServiceFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import TangemNetworkUtils

struct TangemSdkNetworkServiceFactory {
    private let headersProvider = TangemSdkNetworkHeadersProvider()

    func makeService(sessionConfiguration: URLSessionConfiguration? = nil) -> NetworkService {
        let session = makeSession(sessionConfiguration)
        return makeService(session: session)
    }

    func makeService(session: URLSession) -> NetworkService {
        let headers = headersProvider.getHeaders()
        let service = NetworkService(
            session: session,
            additionalHeaders: headers
        )

        return service
    }

    private func makeSession(_ sessionConfiguration: URLSessionConfiguration? = nil) -> URLSession {
        if let sessionConfiguration {
            return TangemTrustEvaluatorUtil.makeSession(configuration: sessionConfiguration)
        }

        return TangemTrustEvaluatorUtil.sharedSession
    }
}
