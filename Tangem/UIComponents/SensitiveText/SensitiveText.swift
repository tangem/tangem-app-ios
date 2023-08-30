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

    init(_ text: String, modify block: @escaping (String) -> String) {
        textType = .modified(text, block)
    }

    var body: some View {
        switch textType {
        case .string(let string):
            Text(viewModel.isHidden ? Constants.maskedBalanceString : string)
        case .attributed(let string):
            Text(viewModel.isHidden ? NSAttributedString(string: Constants.maskedBalanceString) : string)
        case .modified(let string, let modify):
            Text(modify(viewModel.isHidden ? Constants.maskedBalanceString : string))
        }
    }
}

extension SensitiveText {
    enum TextType {
        case string(String)
        case attributed(NSAttributedString)
        case modified(String, _ modify: (String) -> String)
    }
}

extension SensitiveText {
    enum Constants {
        static let maskedBalanceString: String = "***"
    }
}
