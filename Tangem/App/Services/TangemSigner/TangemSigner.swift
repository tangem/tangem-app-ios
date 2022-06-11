//
//  TangemSigner.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemSdk
import Combine

typealias TangemSigner = TransactionSigner & TransactionSignerPublisher

protocol TransactionSignerPublisher {
    var signedCardPublisher: PassthroughSubject<Card, Never> { get }
}

protocol SignerListener: AnyObject {
    func onSign(_ card: Card)
}

private struct TransactionSignerKey: InjectionKey {
    static var currentValue: TangemSigner = DefaultSigner()
}

extension InjectedValues {
    var transactionSigner: TangemSigner {
        get { Self[TransactionSignerKey.self] }
        set { Self[TransactionSignerKey.self] = newValue }
    }
}
