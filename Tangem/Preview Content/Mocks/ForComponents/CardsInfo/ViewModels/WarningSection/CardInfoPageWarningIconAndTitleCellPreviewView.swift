//
//  CardInfoPageWarningIconAndTitleCellPreviewView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct CardInfoPageWarningIconAndTitleCellPreviewView: View {
    @ObservedObject var viewModel: CardInfoPageWarningIconAndTitleCellPreviewViewModel

    var body: some View {
        HStack {
            if let icon = viewModel.icon {
                Image(uiImage: icon)
            }

            Text(viewModel.title)
        }
        .padding()
        .infinityFrame(alignment: .topLeading)
    }
}
