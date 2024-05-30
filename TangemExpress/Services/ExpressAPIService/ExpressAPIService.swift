//
//  ExpressAPIService.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Moya

protocol ExpressAPIService {
    func assets(request: ExpressDTO.Assets.Request) async throws -> [ExpressDTO.Assets.Response]
    func pairs(request: ExpressDTO.Pairs.Request) async throws -> [ExpressDTO.Pairs.Response]
    func providers() async throws -> [ExpressDTO.Providers.Response]
    func exchangeQuote(request: ExpressDTO.ExchangeQuote.Request) async throws -> ExpressDTO.ExchangeQuote.Response
    func exchangeData(request: ExpressDTO.ExchangeData.Request) async throws -> ExpressDTO.ExchangeData.Response
    func exchangeStatus(request: ExpressDTO.ExchangeStatus.Request) async throws -> ExpressDTO.ExchangeStatus.Response
    func exchangeSent(request: ExpressDTO.ExchangeSent.Request) async throws -> ExpressDTO.ExchangeSent.Response
}
