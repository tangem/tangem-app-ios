//
//  ExpressAPITarget+SampleData.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

#if DEBUG
import Foundation

// [REDACTED_TODO_COMMENT]
extension ExpressAPITarget {
    var sampleData: Data {
        switch target {
        case .exchangeHistory(let request):
            return ExchangeHistoryMockLoader.data(forRequest: request)
        case .onrampHistory(let request):
            return OnrampHistoryMockLoader.data(forRequest: request)
        default:
            preconditionFailure("Sample data is not implemented for \(target) target")
        }
    }
}
#endif // DEBUG
