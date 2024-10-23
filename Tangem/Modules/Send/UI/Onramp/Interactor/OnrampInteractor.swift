//
//  OnrampInteractor.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import TangemExpress

protocol OnrampInteractor: AnyObject {
    var isValidPublisher: AnyPublisher<Bool, Never> { get }
}

class CommonOnrampInteractor {
    private weak var input: OnrampInput?
    private weak var output: OnrampOutput?

    private let isValid: CurrentValueSubject<Bool, Never> = .init(true)

    init(input: OnrampInput, output: OnrampOutput) {
        self.input = input
        self.output = output

        bind()
    }

    private func bind() {
        // [REDACTED_TODO_COMMENT]
    }
}

// MARK: - OnrampInteractor

extension CommonOnrampInteractor: OnrampInteractor {
    var isValidPublisher: AnyPublisher<Bool, Never> {
        isValid.eraseToAnyPublisher()
    }
}
