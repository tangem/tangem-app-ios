//
//  MainQRPaymentRequestParser.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct MainQRPaymentRequestParser {
    private let blockchainURIParser = MainQRBlockchainURIParser()
    private let jsonParser = MainQRJSONPaymentParser()
    private let deepLinkParser = MainQRDeepLinkPaymentParser()

    func parse(_ value: String) -> MainQRPaymentRequest? {
        if let request = blockchainURIParser.parse(value) {
            return request
        }

        if let request = jsonParser.parse(value) {
            return request
        }

        if let request = deepLinkParser.parse(
            value,
            blockchainURIParser: blockchainURIParser,
            jsonParser: jsonParser
        ) {
            return request
        }

        return nil
    }
}
