//
//  CutOutMask.swift
//  TangemUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

extension View {
    func cutOutMask<Holes: View>(@ViewBuilder holes: () -> Holes) -> some View {
        mask {
            Rectangle()
                .overlay(content: holes)
                .compositingGroup()
        }
    }
}

struct CutOutHole: View {
    let diameter: CGFloat

    var body: some View {
        Circle()
            .frame(width: diameter, height: diameter)
            .blendMode(.destinationOut)
    }
}
