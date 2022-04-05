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
        GeometryReader { geo in
            Button(action: {
                action()
            }, label: {
                Text("main_manage_tokens_button")
                    .frame(width: geo.size.width, height: 56)
            })
            .foregroundColor(.black)
            .frame(width: geo.size.width, height: 56)
        }
        .frame(height: 56)
        .background(Color.white)
        .cornerRadius(6)
        .shadow(color: .tangemGrayLight5, radius: 2, x: 0, y: 1)
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
