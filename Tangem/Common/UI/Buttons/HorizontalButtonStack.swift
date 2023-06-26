//
//  HorizontalButtonStack.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct HorizontalButtonStack: View {
    struct ButtonInfo {
        let id = UUID()
        let imageName: String
        let title: String
        let action: () -> Void
        let isDisabled: Bool
    }

    var buttons: [ButtonInfo]
    var height: CGFloat = 56

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                if !buttons.isEmpty {
                    ForEach(Array(buttons.enumerated()), id: \.offset) { item in
                        let buttonIndex: Int = item.offset
                        let button: ButtonInfo = item.element
                        let buttonsCount: Int = buttons.count
                        if buttonIndex < buttonsCount {
                            let width: CGFloat = (geo.size.width - (buttonsCount > 1 ? CGFloat(1) : CGFloat(0))) / CGFloat(buttonsCount)
                            Button(action: button.action) {
                                HStack {
                                    Text(button.title)
                                    Image(systemName: button.imageName)
                                }
                            }
                            .disabled(button.isDisabled)
                            .frame(width: width, height: height)
                            .overlay(!button.isDisabled ? Color.clear : Color.white.opacity(0.4))
                        } else {
                            EmptyView()
                        }
                        if buttonIndex < buttonsCount - 1 {
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
        .font(.system(size: 17))
        .foregroundColor(Color.white)
        .frame(height: height)
        .background(Color.tangemGreen)
        .cornerRadius(8)
    }
}

struct TwinButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            HorizontalButtonStack(buttons: [
                .init(
                    imageName: "arrow.up",
                    title: "Topup",
                    action: {},
                    isDisabled: false
                ),
                .init(
                    imageName: "arrow.down",
                    title: "Sell crypto",
                    action: {},
                    isDisabled: false
                ),
                .init(
                    imageName: "arrow.right",
                    title: "Send",
                    action: {},
                    isDisabled: false
                ),
            ])
            HorizontalButtonStack(buttons: [
                .init(
                    imageName: "arrow.up",
                    title: "Topup",
                    action: {},
                    isDisabled: false
                ),
                .init(
                    imageName: "arrow.right",
                    title: "Send",
                    action: {},
                    isDisabled: true
                ),
            ])
            HorizontalButtonStack(buttons: [
                .init(
                    imageName: "arrow.right",
                    title: "Send",
                    action: {},
                    isDisabled: true
                ),
            ])
        }
        .padding()
    }
}
