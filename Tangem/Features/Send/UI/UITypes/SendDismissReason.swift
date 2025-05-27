//
//  SendDismissReason.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

enum SendDismissReason {
    /// The Send flow was dismissed due to tap on the main button.
    case mainButtonTap(type: SendMainButtonType)
    /// For the time being, this case used only as a placeholder value.
    case other
}
