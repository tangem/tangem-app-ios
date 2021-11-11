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
