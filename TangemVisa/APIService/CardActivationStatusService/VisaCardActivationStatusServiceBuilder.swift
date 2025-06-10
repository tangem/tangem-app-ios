//
//  VisaCardActivationStatusServiceBuilder.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public struct VisaCardActivationStatusServiceBuilder {
    private let isMockedAPIEnabled: Bool
    private let apiType: VisaAPIType

    public init(apiType: VisaAPIType, isMockedAPIEnabled: Bool) {
        self.apiType = apiType
        self.isMockedAPIEnabled = isMockedAPIEnabled
    }

    public func build(urlSessionConfiguration: URLSessionConfiguration) -> VisaCardActivationStatusService {
        if isMockedAPIEnabled {
            return CardActivationStatusServiceMock()
        }

        return CommonCardActivationStatusService(
            apiType: apiType,
            apiService: .init(
                provider: MoyaProviderBuilder().buildProvider(configuration: urlSessionConfiguration),
                decoder: JSONDecoderFactory().makePayAPIDecoder()
            )
        )
    }
}
