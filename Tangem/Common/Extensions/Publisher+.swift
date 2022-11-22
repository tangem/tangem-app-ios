//
//  Publisher+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

extension Publisher where Output: Equatable {
    var uiPublisher: AnyPublisher<Output, Failure> {
        dropFirst()
            .debounce(for: 0.6, scheduler: DispatchQueue.main)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    var uiPublisherWithFirst: AnyPublisher<Output, Failure> {
        debounce(for: 0.6, scheduler: DispatchQueue.main)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}

extension Publisher where Failure == Never {
    func weakAssign<Root: AnyObject>(to keyPath: ReferenceWritableKeyPath<Root, Output>, on root: Root) -> AnyCancellable {
        sink { [weak root] in
            root?[keyPath: keyPath] = $0
        }
    }

    func weakAssign<Root: AnyObject>(to keyPath: ReferenceWritableKeyPath<Root, Output?>, on root: Root) -> AnyCancellable {
        sink { [weak root] in
            root?[keyPath: keyPath] = $0
        }
    }

    func weakAssignAnimated<Root: AnyObject>(to keyPath: ReferenceWritableKeyPath<Root, Output>, on root: Root) -> AnyCancellable {
        sink { [weak root] value in
            withAnimation {
                root?[keyPath: keyPath] = value
            }
        }
    }

    func weakAssignAnimated<Root: AnyObject>(to keyPath: ReferenceWritableKeyPath<Root, Output?>, on root: Root) -> AnyCancellable {
        sink { [weak root] value in
            withAnimation {
                root?[keyPath: keyPath] = value
            }
        }
    }
}

public extension Publisher {
    /// Subscribes to current publisher without handling events
    func sink() -> AnyCancellable {
        return sink(receiveCompletion: { _ in }, receiveValue: { _ in })
    }

    /// `receiveValue` clouser from default `sink` method
    func receiveValue(_ receiveValue: @escaping ((Self.Output) -> Void)) -> AnyCancellable {
        sink(receiveCompletion: { _ in }, receiveValue: receiveValue)
    }

    /// `receiveCompletion` clouser from default `sink` method
    func receiveCompletion(_ receiveCompletion: @escaping ((Subscribers.Completion<Self.Failure>) -> Void)) -> AnyCancellable {
        sink(receiveCompletion: receiveCompletion, receiveValue: { _ in })
    }

    /// Transforms any received value to Void
    func mapVoid() -> Publishers.Map<Self, Void> {
        map { _ in }
    }

    func eraseError() -> AnyPublisher<Output, Error> {
        return self.mapError { error -> Error in
            return error as Error
        }
        .eraseToAnyPublisher()
    }
}

extension Publisher where Output == Void, Failure == Error {
    static var just: AnyPublisher<Output, Failure> {
        Just(()).setFailureType(to: Failure.self).eraseToAnyPublisher()
    }
}

extension Publisher where Output == Void, Failure == Never {
    static var just: AnyPublisher<Output, Failure> {
        Just(()).eraseToAnyPublisher()
    }
}
