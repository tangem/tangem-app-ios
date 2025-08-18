//
//  SendFinishInputOutput.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol SendFinishRoutable: AnyObject {
    func openExplorer(url: URL)
    func openShareSheet(url: URL)
}

protocol SendFinishInput: AnyObject {
    var transactionExplorerURL: AnyPublisher<URL?, Never> { get }
    var transactionSentDate: AnyPublisher<Date, Never> { get }
}
