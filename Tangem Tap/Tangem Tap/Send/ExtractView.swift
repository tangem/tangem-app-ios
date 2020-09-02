//
//  ExtractView.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemSdk

struct ExtractView: View {
    @ObservedObject var model: ExtractViewModel
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack {
                ForEach(1..<20) {
                Text("\($0)")
                }
                Spacer()
                HStack(alignment: .center, spacing: 8.0) {
                Spacer()
                Button(action: {
                
                }) { HStack(alignment: .center, spacing: 16.0) {
                Text("details_button_send")
                Spacer()
                Image("arrow.right")
                }.padding(.horizontal)
                }
            .buttonStyle(TangemButtonStyle(size: .big,
                colorStyle: .green,
                isDisabled: !self.model.isSendEnabled))
                .disabled(!self.model.isSendEnabled)
                }
                }
            .padding()
            .frame(minWidth: geometry.size.width,
                maxWidth: geometry.size.width,
                minHeight: geometry.size.height,
                maxHeight: .infinity, alignment: .top)
                }
        }
    }
}

struct ExtractView_Previews: PreviewProvider {
    @State static var sdkService: TangemSdkService = {
        let service = TangemSdkService()
        service.cards[Card.testCard.cardId!] = CardViewModel(card: Card.testCard)
        return service
    }()
    
    @State static var cardViewModel = CardViewModel(card: Card.testCard)
    
    static var previews: some View {
        ExtractView(model: ExtractViewModel(cardViewModel: $cardViewModel, sdkSerice: $sdkService))
    }
}
