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
    @EnvironmentObject var viewModel: SensitiveTextVisibilityService
    private let textType: TextType

    init(_ text: String) {
        textType = .string(text)
    }

    init(_ text: NSAttributedString) {
        textType = .attributed(text)
    }

    init(builder: @escaping (String) -> String, sensitive: String) {
        textType = .builder(builder: builder, sensitive: sensitive)
    }

    var body: some View {
        switch textType {
        case .string(let string):
            Text(viewModel.isHidden ? Constants.maskedBalanceString : string)
        case .attributed(let string):
            Text(viewModel.isHidden ? NSAttributedString(string: Constants.maskedBalanceString) : string)
        case .builder(let builder, let sensitive):
            Text(builder(viewModel.isHidden ? Constants.maskedBalanceString : sensitive))
        }
    }
}

extension SensitiveText {
    enum TextType {
        case string(String)
        case attributed(NSAttributedString)
        case builder(builder: (String) -> String, sensitive: String)
    }
}

extension SensitiveText {
    enum Constants {
        static let maskedBalanceString: String = "\u{2217}\u{2217}\u{2217}"
    }
}
