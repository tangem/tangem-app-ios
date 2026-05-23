//
//  ExchangeHistoryMockLoader.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

#if DEBUG
import Foundation

// [REDACTED_TODO_COMMENT]
final class ExchangeHistoryMockLoader {
    static func data(forRequest request: ExpressDTO.HistoryRequest) -> Data {
        let cursor = request.cursor?.value as? String
        let resourceName: String

        switch cursor {
        case nil:
            // According to the API contract, the initial request must have a null cursor
            resourceName = "exchange_history_page1"
        case .some("p2"):
            resourceName = "exchange_history_page2"
        case .some("p3"):
            resourceName = "exchange_history_page3"
        default:
            preconditionFailure("Invalid cursor: \(String(describing: cursor))")
        }

        let bundle = Bundle(for: Self.self)

        guard
            let url = bundle.url(forResource: resourceName, withExtension: "json"),
            let data = try? Data(contentsOf: url)
        else {
            preconditionFailure("Missing \(String(describing: resourceName)) file")
        }

        return data
    }

    private init() {}
}
#endif // DEBUG
