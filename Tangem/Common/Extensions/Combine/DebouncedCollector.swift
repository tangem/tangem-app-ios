//
//  DebouncedCollector.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

extension Publishers {
    struct DebouncedCollector<Upstream: Publisher, S: Scheduler>: Publisher {
        typealias Output = [Upstream.Output]
        typealias Failure = Upstream.Failure

        private let upstream: Upstream
        private let dueTime: S.SchedulerTimeType.Stride
        private let scheduler: S
        private let options: S.SchedulerOptions?

        init(upstream: Upstream, dueTime: S.SchedulerTimeType.Stride, scheduler: S, options: S.SchedulerOptions?) {
            self.upstream = upstream
            self.dueTime = dueTime
            self.scheduler = scheduler
            self.options = options
        }

        func receive<Subscriber>(
            subscriber: Subscriber
        ) where Subscriber: Combine.Subscriber, Failure == Subscriber.Failure, Output == Subscriber.Input {
            var reset = false
            upstream
                .receive(on: scheduler)
                .scan([]) { reset ? [$1] : $0 + [$1] }
                .handleEvents(receiveOutput: { _ in reset = false })
                .debounce(for: dueTime, scheduler: scheduler, options: options)
                .handleEvents(receiveOutput: { _ in reset = true })
                .receive(subscriber: subscriber)
        }
    }
}

extension Publisher {
    /// This method will collect all the sequence elements into an array during the debounce time
    /// - Parameters:
    ///   - debouncedTime: The time the publisher should collect  elements before publishing an array of elements
    ///   - scheduler: The scheduler on which this publisher delivers elements
    ///   - options: Scheduler options that customize this publisher’s delivery of elements.
    func collect<S: Scheduler>(
        debouncedTime: S.SchedulerTimeType.Stride,
        scheduler: S,
        options: S.SchedulerOptions? = nil
    ) -> Publishers.DebouncedCollector<Self, S> {
        .init(upstream: self, dueTime: debouncedTime, scheduler: scheduler, options: options)
    }
}
