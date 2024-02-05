//
//  Text+AttributedStringParameters.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct AttributedTextParam {
    let text: String
    let font: Font
    let color: Color
}

struct AttributedStringParameters {
    let params: [AttributedTextParam]

    static var emptyString: AttributedStringParameters {
        makeDefaultParams(for: BalanceFormatter.defaultEmptyBalanceString)
    }

    static func makeDefaultParams(for string: String) -> AttributedStringParameters {
        let formatter = BalanceFormatter()
        return formatter.formatAttributedTotalBalance(fiatBalance: string)
    }
}

extension Text {
    init(_ attributedStringParams: AttributedStringParameters) {
        self = Text("")

        for chunk in attributedStringParams.params {
            self = self + Text(chunk.text).font(chunk.font).foregroundColor(chunk.color)
        }
    }
}
