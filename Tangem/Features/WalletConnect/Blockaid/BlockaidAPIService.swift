//
//  BlockaidAPIService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Moya

protocol BlockaidAPIService {
    func scan(url: URL) async throws -> BlockaidDTO.Scan.Response
}

final class CommonBlockaidAPIService: BlockaidAPIService {
    private let provider: MoyaProvider<BlockaidTarget>
    private let apiKey: String

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601WithFractionalSeconds
        return decoder
    }()
    
    init(provider: MoyaProvider<BlockaidTarget>, apiKey: String) {
        self.provider = provider
        self.apiKey = apiKey
    }
    
    func scan(url: URL) async throws -> BlockaidDTO.Scan.Response {
        let request = BlockaidDTO.Scan.Request(url: url.absoluteString)
        let target = BlockaidTarget.init(apiKey: apiKey, target: .scan(request: request))
        var response = try await provider.requestPublisher(target).async()
        
        do {
            response = try response.filterSuccessfulStatusAndRedirectCodes()
        } catch {
            // [REDACTED_TODO_COMMENT]

            throw error
        }

        return try JSONDecoder().decode(BlockaidDTO.Scan.Response.self, from: response.data)
    }
}
