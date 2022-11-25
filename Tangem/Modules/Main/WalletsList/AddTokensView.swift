//
//  AddTokensView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct AddTokensView: View {
    var action: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button {
                action()
            } label: {
                Text("main_manage_tokens")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(Color.black)
            }
            .buttonStyle(PlainButtonStyle())
            .cornerRadius(14)
            .animation(nil)
        }
    }
}

struct AddTokensView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.tangemGrayLight5
            AddTokensView(action: {})
                .padding()
        }
    }
}
