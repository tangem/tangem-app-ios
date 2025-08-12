//
//  HotOnboardingSeedPhraseResolver.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol HotOnboardingSeedPhraseResolver {
    var words: [String] { get }
    var validationWords: HotOnboardingSeedPhraseValidationWords { get }
}

struct HotOnboardingSeedPhraseValidationWords {
    let second: String
    let seventh: String
    let eleventh: String
}
