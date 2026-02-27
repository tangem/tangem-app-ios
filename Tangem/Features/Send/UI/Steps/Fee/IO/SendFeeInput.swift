//
//  SendFeeInput.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol SendFeeInput: AnyObject {
    var selectedFee: TokenFee? { get }
    var selectedFeePublisher: AnyPublisher<TokenFee, Never> { get }

    var shouldShowFeeSelectorRow: AnyPublisher<Bool, Never> { get }
    var supportFeeSelectionPublisher: AnyPublisher<Bool, Never> { get }
}

extension SendFeeInput {
    var shouldShowFeeSelectorRow: AnyPublisher<Bool, Never> { .just(output: true) }
}
