//
//  CardInfoPageTransactionDefaultCellPreviewView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct CardInfoPageTransactionDefaultCellPreviewView: View {
    @ObservedObject var viewModel: CardInfoPageTransactionDefaultCellPreviewViewModel

    let contentColor: Color

    var body: some View {
        VStack {
            Text(viewModel.title)
                .font(.caption)
                .fontWeight(.bold)
                .lineLimit(1)
                .allowsTightening(true)

            Button("Press me!", action: viewModel.onTap)
        }
        .frame(height: 68.0)
        .infinityFrame()
        .background(contentColor)
    }
}
