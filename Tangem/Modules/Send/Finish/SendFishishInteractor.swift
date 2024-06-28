//
//  SendFishishInteractor.swift
//  Tangem
//
//  Created by Sergey Balashov on 28.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

typealias SendFinishInteractor = SendSummaryInteractor

class CommonSendFinishInteractor: SendFinishInteractor {
    func setup(input: any SendSummaryInput, output: any SendSummaryOutput) {}

    var transactionDescription: AnyPublisher<String?, Never> { .just(output: nil) }
}
