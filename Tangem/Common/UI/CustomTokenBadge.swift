//
//  CustomTokenBadge.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct CustomTokenBadge: View {
    var body: some View {
        Text("common_custom".localized)
            .font(.system(size: 12))
            .foregroundColor(.tangemGrayDark)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(Color.tangemGrayDark.opacity(0.15))
            .cornerRadius(6)
    }
}
