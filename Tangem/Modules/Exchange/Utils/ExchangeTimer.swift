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
    private var timer = Timer
        .publish(every: 1.0, on: .main, in: .common)
        .autoconnect()

    func startTimer() -> AnyPublisher<State, Never> {
        return timer
            .map({ [weak self] output -> State in
                guard let self else { return State.expired }

                let timePassedSinceStart = output.timeIntervalSince(self.start)
                if timePassedSinceStart >= self.timeToRefresh {
                    return .expired
                } else {
                    return .passed(seconds: timePassedSinceStart)
                }
            })
            .eraseToAnyPublisher()
    }

    func cancel() {
        timer.upstream.connect().cancel()
    }
}
