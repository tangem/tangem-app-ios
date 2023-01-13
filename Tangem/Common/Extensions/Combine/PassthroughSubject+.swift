//
//  PassthroughSubject+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine

extension PassthroughSubject {
    static func emittingValues<T: AsyncSequence>(
        from sequence: T
    ) -> Self where T.Element == Output, Failure == Error {
        let subject = Self()

        Task {
            do {
                for try await value in sequence {
                    subject.send(value)
                }

                subject.send(completion: .finished)
            } catch {
                subject.send(completion: .failure(error))
            }
        }

        return subject
    }

    static func emittingValues<T: AsyncSequence>(from sequence: T) -> Self where T.Element == Output, Failure == Never {
        let subject = Self()

        Task {
            do {
                for try await value in sequence {
                    subject.send(value)
                }

                subject.send(completion: .finished)
            } catch {
                subject.send(completion: .finished)
            }

        }

        return subject
    }
}
