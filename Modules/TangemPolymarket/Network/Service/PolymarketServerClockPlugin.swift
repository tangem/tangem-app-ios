//
//  PolymarketServerClockPlugin.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Moya

struct PolymarketServerClockPlugin: PluginType {
    let serverClock: PolymarketServerClock

    func didReceive(_ result: Result<Response, MoyaError>, target: any TargetType) {
        let httpResponse: HTTPURLResponse? = switch result {
        case .success(let response): response.response
        case .failure(let error): error.response?.response
        }

        guard
            let header = httpResponse?.value(forHTTPHeaderField: Constants.dateHeader),
            let serverDate = Self.headerDateFormatter.date(from: header)
        else {
            PolymarketLogger.warning(
                "The backend answered without a readable date, leaving the deadline on the device clock"
            )
            return
        }

        serverClock.record(serverDate: serverDate)
    }
}

// MARK: - Header date

private extension PolymarketServerClockPlugin {
    static let headerDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"

        return formatter
    }()

    enum Constants {
        static let dateHeader = "Date"
    }
}
