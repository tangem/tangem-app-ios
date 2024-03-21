//
//  SendFiatCryptoAdapterMock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class SendFiatCryptoAdapterMock: SendFiatCryptoAdapter {
    var amountAlternative: AnyPublisher<String?, Never> { .just(output: "100 $") }

    func setInput(_ input: SendFiatCryptoAdapterInput) {}
    func setOutput(_ output: SendFiatCryptoAdapterOutput) {}
    func setAmount(_ decimal: Decimal?) {}
    func setUseFiatCalculation(_ useFiatCalculation: Bool) {}
    func setCrypto(_ decimal: Decimal?) {}
}
