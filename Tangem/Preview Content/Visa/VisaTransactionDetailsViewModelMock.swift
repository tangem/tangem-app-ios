//
//  VisaTransactionDetailsViewModelMock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemVisa
import TangemFoundation

extension VisaTransactionDetailsViewModel {
    static var uiMock: VisaTransactionDetailsViewModel {
        let decoder = JSONDecoder()

        do {
            let url = Bundle.main.url(forResource: "visaSingleTransaction", withExtension: "json")!
            let jsonContent = try String(contentsOf: url)
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            decoder.dateDecodingStrategy = .iso8601WithFractionalSeconds

            let transaction = try decoder.decode(VisaTransactionRecord.self, from: jsonContent.data(using: .utf8)!)
            let visaBlockchain = VisaUtilities.visaBlockchain
            let tokenItem = TokenItem.token(VisaUtilities.mockToken, .init(visaBlockchain, derivationPath: nil))
            return .init(tokenItem: tokenItem, transaction: transaction, emailConfig: .visaDefault(subject: .dispute), router: nil)
        } catch {
            VisaLogger.debug("\n\n\nFailed to create UI mock. Error: \(error)\n\n\n")
            fatalError("Failed to create UI mock. Error: \(error)")
        }
    }
}
