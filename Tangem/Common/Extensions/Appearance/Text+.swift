//
//  Text+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

extension Text {
    func style(font: Font, color: Color) -> Text {
        self.font(font).foregroundColor(color)
    }
}
