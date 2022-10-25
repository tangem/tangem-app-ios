//
//  Exchange+Timer.swift
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

    private let start: Date = Date()
    private var subscription: AnyCancellable?

    func startTimer(callback: @escaping (State) -> ()) {
        subscription = Timer
            .publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink(receiveValue: { [weak self] output in
                guard let self else { return }

                let timePassedSinceStart = output.timeIntervalSince(self.start)
                if timePassedSinceStart > 10 {
                    callback(.expired)
                    self.subscription = nil
                } else {
                    callback(.passed(seconds: timePassedSinceStart))
                }
            })
    }

    func cancel() {
        subscription = nil
    }
}
