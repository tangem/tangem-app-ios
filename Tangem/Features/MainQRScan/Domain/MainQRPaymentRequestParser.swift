//
//  MainQRPaymentRequestParser.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct MainQRPaymentRequestParser {
    enum Source {
        case blockchainURI
        case json
        case deepLink
    }

    struct ParsedResult {
        let request: MainQRPaymentRequest
        let source: Source
    }

    private let blockchainURIParser = MainQRBlockchainURIParser()
    private let jsonParser = MainQRJSONPaymentParser()
    private let deepLinkParser = MainQRDeepLinkPaymentParser()

    func parse(_ value: String) -> ParsedResult? {
        if let request = blockchainURIParser.parse(value) {
            return ParsedResult(request: request, source: .blockchainURI)
        }

        if let request = jsonParser.parse(value) {
            return ParsedResult(request: request, source: .json)
        }

        if let request = deepLinkParser.parse(
            value,
            blockchainURIParser: blockchainURIParser,
            jsonParser: jsonParser
        ) {
            return ParsedResult(request: request, source: .deepLink)
        }

        return nil
    }
}
