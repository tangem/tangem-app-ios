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
    @ObservedObject private var viewModel: SensitiveTextVisibilityService = .shared
    private let textType: TextType

    init(_ text: String) {
        textType = .string(text)
    }

    init(_ text: NSAttributedString) {
        textType = .attributed(text)
    }

    init(_ text: String, wrap block: @escaping (String) -> String) {
        textType = .wrapped(text, block)
    }

    var body: some View {
        switch textType {
        case .string(let string):
            Text(viewModel.isHidden ? Constants.maskedBalanceString : string)
        case .attributed(let string):
            Text(viewModel.isHidden ? NSAttributedString(string: Constants.maskedBalanceString) : string)
        case .wrapped(let string, let wrap):
            Text(wrap(viewModel.isHidden ? Constants.maskedBalanceString : string))
        }
    }
}

extension SensitiveText {
    enum TextType {
        case string(String)
        case attributed(NSAttributedString)
        case wrapped(String, _ modify: (String) -> String)
    }
}

extension SensitiveText {
    enum Constants {
        static let maskedBalanceString: String = "***"
    }
}
