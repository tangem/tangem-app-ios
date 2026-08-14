//
//  Publisher+AsyncStream.swift
//  TangemFoundation
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

public extension Publishers {
    static func stream<Element>(
        _ makeStream: @escaping @Sendable () -> AsyncStream<Element>
    ) -> some Publisher<Element, Never> {
        Deferred {
            let subject = CurrentValueSubject<Element?, Never>(nil)
            let task = Task {
                for await element in makeStream() {
                    subject.send(element)
                }

                subject.send(completion: .finished)
            }

            return subject
                .compactMap(\.self)
                .handleEvents(receiveCancel: {
                    task.cancel()
                })
        }
    }
}
