//
//  HorizontalButtonStack.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct HorizontalButtonStack: View {
    struct ButtonInfo {
        let imageName: String
        let title: LocalizedStringKey
        let action: () -> Void
        let isDisabled: Bool
    }
    
    var buttons: [ButtonInfo]
    var height: CGFloat = 56
    
    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                if buttons.count > 0 {
                    ForEach(0..<buttons.count) { (buttonIndex) in
                        Button(action: buttons[buttonIndex].action) {
                            HStack {
                                Text(buttons[buttonIndex].title)
                                Image(buttons[buttonIndex].imageName)
                            }
                        }
                        .disabled(buttons[buttonIndex].isDisabled)
                        .frame(width: (geo.size.width - (buttons.count > 1 ? CGFloat(1) : CGFloat(0))) / CGFloat(buttons.count), height: height)
                        .overlay(!buttons[buttonIndex].isDisabled ? Color.clear : Color.white.opacity(0.4))
                        if buttonIndex < buttons.count - 1 {
                            Color.white
                                .opacity(0.3)
                                .frame(width: 1)
                                .padding(.vertical, 10)
                                .cornerRadius(0.5)
                        }
                    }
                }
            }
            .frame(width: geo.size.width, height: height)
            
        }
        .font(Font.custom("SairaSemiCondensed-Bold", size: 15.0))
        .foregroundColor(Color.white)
        .frame(height: height)
        .background(Color.tangemTapGreen)
        .cornerRadius(8)
    }
}

struct TwinButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            HorizontalButtonStack(buttons: [
                .init(imageName: "arrow.up",
                      title: "Topup",
                      action: {},
                      isDisabled: false),
                .init(imageName: "arrow.down",
                      title: "Sell crypto",
                      action: {},
                      isDisabled: false),
                .init(imageName: "arrow.right",
                      title: "Send",
                      action: {},
                      isDisabled: false)
            ])
            HorizontalButtonStack(buttons: [
                .init(imageName: "arrow.up",
                      title: "Topup",
                      action: {},
                      isDisabled: false),
                .init(imageName: "arrow.right",
                      title: "Send",
                      action: {},
                      isDisabled: true)
            ])
            HorizontalButtonStack(buttons: [
                .init(imageName: "arrow.right",
                      title: "Send",
                      action: {},
                      isDisabled: true)
            ])
        }
        .padding()
    }
}
