//
//  WarningView.swift
//  Tangem Tap
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
        .background(Color.tangemTapGrayDark5)
        .cornerRadius(50)
    }
}

struct WarningView: View {
    
    let warning: TapWarning
    var buttonAction: () -> Void = { }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 0) {
                Text(warning.title)
                    .font(.system(size: 14, weight: .bold))
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                    .foregroundColor(.white)
                Text(warning.message)
                    .font(.system(size: 13, weight: .medium))
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(8)
                    .foregroundColor(warning.priority.messageColor)
                    .padding(.bottom, warning.type.isWithAction ? 8 : 16)
                
                if warning.type.isWithAction {
                    HStack {
                        Spacer()
                        Button(action: buttonAction, label: {
                            Text("wallet_warning_button_ok")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        })
                    }
                    .padding(EdgeInsets(top: 0, leading: 20, bottom: 16, trailing: 20))
                }
            }
            Spacer()
        }
        .padding(.horizontal, 24)
        .background(warning.priority.backgroundColor)
        .cornerRadius(6)
    }
}

struct WarningView_Previews: PreviewProvider {
    @State static var warnings: [TapWarning] = [
        WarningEvent.numberOfSignedHashesIncorrect.warning,
        TapWarning(title: "Warning", message: "Blockchain is currently unavailable", priority: .critical, type: .permanent),
        TapWarning(title: "Good news, everyone!", message: "New Tangem Cards available. Visit our web site to learn more", priority: .info, type: .temporary),
        TapWarning(title: "Attention!", message: "Something huuuuuge is going to happen!", priority: .warning, type: .permanent),
        
    ]
    static var previews: some View {
        ScrollView {
            ForEach(Array(warnings.enumerated()), id: \.element) { (i, item) in
                WarningView(warning: warnings[i]) {
                    withAnimation {
                        print("Ok button tapped")
                        warnings.remove(at: i)
                    }
                }
                .transition(.opacity)
            }
        }
        
    }
}
