//
//  ExpressAPIService.swift
//  TangemSwapping
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Moya

// [REDACTED_TODO_COMMENT]

protocol ExpressAPIService {
    func assets(request: ExpressDTO.Assets.Request) async throws
    func pairs(request: ExpressDTO.Pairs.Request) async throws
    func providers() async throws
    func exchangeQuote(request: ExpressDTO.ExchangeQuote.Request) async throws
    func exchangeData(request: ExpressDTO.ExchangeData.Request) async throws
    func exchangeResult(request: ExpressDTO.ExchangeResult.Request) async throws
}
