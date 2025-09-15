//
//  Publisher+.swift
//  TangemFoundation
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import Combine

public extension Publisher {
    func receiveOnMain() -> Publishers.ReceiveOn<Self, DispatchQueue> {
        receive(on: DispatchQueue.main)
    }

    func receiveOnGlobal(qos: DispatchQoS.QoSClass = .default) -> Publishers.ReceiveOn<Self, DispatchQueue> {
        receive(on: DispatchQueue.global(qos: qos))
    }

    func withWeakCaptureOf<Object>(
        _ object: Object
    ) -> Publishers.CompactMap<Self, (Object, Self.Output)> where Object: AnyObject {
        return compactMap { [weak object] output in
            guard let object = object else { return nil }

            return (object, output)
        }
    }

    func withUnownedCaptureOf<Object>(
        _ object: Object
    ) -> Publishers.Map<Self, (Object, Self.Output)> where Object: AnyObject {
        return map { [unowned object] output in
            return (object, output)
        }
    }

    static var empty: AnyPublisher<Output, Failure> {
        return Empty()
            .eraseToAnyPublisher()
    }

    func debounce(
        for interval: DispatchQueue.SchedulerTimeType.Stride,
        scheduler: DispatchQueue = .global(),
        if shouldDebounce: @escaping (Output) -> Bool
    ) -> some Publisher<Output, Failure> {
        map { value in
            guard shouldDebounce(value) else {
                return Just(value)
                    .setFailureType(to: Failure.self)
                    .eraseToAnyPublisher()
            }

            return Just(value)
                .setFailureType(to: Failure.self)
                .delay(for: interval, scheduler: scheduler)
                .eraseToAnyPublisher()
        }
        .switchToLatest()
    }
}
