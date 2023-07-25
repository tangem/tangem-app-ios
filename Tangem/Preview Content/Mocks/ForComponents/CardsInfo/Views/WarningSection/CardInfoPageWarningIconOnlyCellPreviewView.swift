//
//  CardInfoPageWarningIconOnlyCellPreviewView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct CardInfoPageWarningIconOnlyCellPreviewView: View {
    @ObservedObject var viewModel: CardInfoPageWarningIconOnlyCellPreviewViewModel

    var body: some View {
        HStack {
            if let icon = viewModel.icon {
                Image(uiImage: icon)
            }

            Text("No title provided")
                .foregroundColor(.gray)
        }
        .padding()
        .infinityFrame(alignment: .topLeading)
    }
}
