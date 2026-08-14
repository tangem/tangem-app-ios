//
//  TangemPayCashbackAccrualsViewData.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct TangemPayCashbackAccrualsViewData: Identifiable {
    let id = UUID()
    let docs: [Doc]
}

extension TangemPayCashbackAccrualsViewData {
    struct Doc: Identifiable {
        let id: String
        let title: String
        let url: URL
    }
}

// MARK: - Previews

#if DEBUG
extension TangemPayCashbackAccrualsViewData {
    static let preview = TangemPayCashbackAccrualsViewData(
        docs: [
            Doc(
                id: "88507e81-3d76-4b59-9842-5f8e5bbee46f",
                title: "All categories without cashback",
                url: URL(string: "https://tangem.com/docs/en/tangem-pay-cashback-excluded-mccs.pdf")!
            ),
            Doc(
                id: "cf690333-c923-4f79-802c-9a7ce6b51a57",
                title: "Full terms of cashback program",
                url: URL(string: "https://tangem.com/docs/en/tangem-pay-cashback-terms.pdf")!
            ),
        ]
    )

    static let previewWithoutDocs = TangemPayCashbackAccrualsViewData(docs: [])
}
#endif
