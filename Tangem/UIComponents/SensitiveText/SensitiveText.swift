//
//  SensitiveText.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct SensitiveText: View {
    @ObservedObject private var viewModel: ConcealBalanceProvider = .shared
    private let textType: TextType

    init(_ text: String) {
        textType = .string(text)
    }

    init(_ text: NSAttributedString) {
        textType = .attributed(text)
    }

    var body: some View {
        switch textType {
        case .string(let string):
            Text(viewModel.isConceal ? Constants.maskedBalanceString : string)
        case .attributed(let string):
            Text(viewModel.isConceal ? NSAttributedString(string: Constants.maskedBalanceString) : string)
        }
    }
}

extension SensitiveText {
    enum TextType {
        case string(String)
        case attributed(NSAttributedString)
    }
}

extension SensitiveText {
    enum Constants {
        static let maskedBalanceString: String = "***"
    }
}
