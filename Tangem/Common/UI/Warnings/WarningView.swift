//
//  WarningView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import SwiftUI

struct Counter {
    let number: Int
    let totalCount: Int
}

struct CounterView: View {
    
    let counter: Counter
    
    var body: some View {
        HStack {
            Text("\(counter.number)/\(counter.totalCount)")
                .font(.system(size: 13, weight: .medium, design: .default))
        }
        .padding(EdgeInsets(top: 2, leading: 5, bottom: 2, trailing: 5))
        .frame(minWidth: 40, minHeight: 24, maxHeight: 24)
        .background(Color.tangemGrayDark5)
        .cornerRadius(50)
    }
}

struct WarningView: View {
    
    let warning: AppWarning
    var buttonAction: (WarningButton) -> Void = { _ in }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text(warning.title)
                    .font(.system(size: 14, weight: .bold))
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                    .foregroundColor(.white)
                if warning.event?.canBeDismissed ?? false {
                    Spacer()
                    Button(action: { buttonAction(.dismiss) }, label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.tangemGrayDark)
                            .frame(width: 26, height: 26)
                    })
                    .buttonStyle(PlainButtonStyle())
                    .offset(x: 6)
                }
            }
            if !warning.message.isEmpty {
                Text(warning.message)
                    .font(.system(size: 13, weight: .medium))
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(minHeight: warning.type.isWithAction ? CGFloat(25) : CGFloat(0), alignment: .topLeading)
                    .lineSpacing(8)
                    .foregroundColor(warning.priority.messageColor)
                    .padding(.bottom, warning.type.isWithAction ? CGFloat(8) : CGFloat(16))
            }
            buttons
            Color.clear.frame(height: 0, alignment: .center)
        }
        .padding(.horizontal, 16)
        .background(warning.priority.backgroundColor)
        .fixedSize(horizontal: false, vertical: true)
        .cornerRadius(6)
    }
    
    var warningButtons: [WarningButton] {
        if let buttons = warning.event?.buttons, !buttons.isEmpty {
            return buttons
        } else {
           return [.okGotIt]
        }
    }
    
    @ViewBuilder var buttons: some View {
        if warning.type.isWithAction {
            HStack(spacing: 0) {
                Spacer(minLength: 0)
                ForEach(Array(warningButtons.enumerated()), id: \.element.id, content: { item in
                    Button(action: {
                        buttonAction(item.element)
                    }, label: {
                        Text(item.element.buttonTitle)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    })
                    .buttonStyle(PlainButtonStyle())
                    .frame(height: 24)
                    if warningButtons.count > 1, item.offset < warningButtons.count - 1 {
                        Color.tangemGrayDark5
                            .frame(width: 1, height: 16)
                            .padding(.horizontal, 4)
                    }
                })
            }
            .padding(EdgeInsets(top: 0, leading: 20, bottom: 12, trailing: 0))
        } else {
            EmptyView()
        }
    }
    
}

struct WarningView_Previews: PreviewProvider {
    @State static var warnings: [AppWarning] = [
        WarningEvent.numberOfSignedHashesIncorrect.warning,
        WarningEvent.rateApp.warning,
        AppWarning(title: "Warning", message: "Blockchain is currently unavailable", priority: .critical, type: .permanent),
        AppWarning(title: "Good news, everyone!", message: "New Tangem Cards available. Visit our web site to learn more", priority: .info, type: .temporary),
        AppWarning(title: "Attention!", message: "Something huuuuuge is going to happen! Something huuuuuge is going to happen! Something huuuuuge is going to happen! Something huuuuuge is going to happen! Something huuuuuge is going to happen! Something huuuuuge is going to happen!", priority: .warning, type: .permanent),
        WarningsList.multiWalletSignedHashes
    ]
    static var previews: some View {
        ScrollView {
            ForEach(Array(warnings.enumerated()), id: \.element) { (i, item) in
                WarningView(warning: warnings[i], buttonAction: { _ in
                    withAnimation {
                        print("Ok button tapped")
                        warnings.remove(at: i)
                    }
                })
                .transition(.opacity)
            }
        }
        
    }
}
