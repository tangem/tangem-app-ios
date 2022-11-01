//
//  ExchangeTimer.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class ExchangeTimer {
    enum State {
        case passed(seconds: TimeInterval)
        case expired
    }

    private let timeToRefresh: TimeInterval = 10
    private let start: Date = Date()
    private var subscription: AnyCancellable?

    func startTimer(completion: @escaping (State) -> ()) {
        subscription = Timer
            .publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink(receiveValue: { [weak self] output in
                guard let self else { return }

                let timePassedSinceStart = output.timeIntervalSince(self.start)
                if timePassedSinceStart >= self.timeToRefresh {
                    completion(.expired)
                    self.subscription = nil
                } else {
                    completion(.passed(seconds: timePassedSinceStart))
                }
            })
    }

    func cancel() {
        subscription = nil
    }
}
