//
//  Text+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

extension Text {
    func style(_ style: TypographyStyle, color: Color) -> Text {
        font(style.font).foregroundColor(color)
    }
}
