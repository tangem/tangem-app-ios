//
//  NoAccountView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct MessageView: View {
    enum MessageType {
        case error, message
        
        var iconName: String {
            switch self {
            case .error: return "exclamationmark.circle"
            case .message: return "info.circle"
            }
        }
        
        var iconColor: Color {
            switch self {
            case .error: return .tangemWarning
            case .message: return .tangemGreen
            }
        }
    }
    
    var title: String
    var subtitle: String
    var type: MessageType
    
    var body: some View {
        HStack(alignment: .textAndImage, spacing: 18.0) {
            Spacer()
                .frame(width: 8.0, height: nil, alignment: .center)
            Image(systemName: type.iconName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                .foregroundColor(type.iconColor)
                    .frame(width: 26.5, height: 26.5)
                    .alignmentGuide(.textAndImage) { d in d[.bottom] / 2 }

            VStack(alignment: .leading, spacing: 6.0) {
                Text(title)
                    .font(Font.system(size: 20.0, weight: .bold, design: .default))
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .alignmentGuide(.textAndImage) { d in d[.bottom] / 2 }
                    .foregroundColor(Color.tangemGrayDark6)
                    .minimumScaleFactor(0.8)
                Text(subtitle)
                    .font(Font.system(size: 13.0))
                    .fontWeight(.medium)
                    .foregroundColor(Color.tangemGrayDark)
                    .multilineTextAlignment(.leading)
            }
            .padding(.vertical, 16.0)
            Spacer()
        }
        .background(Color.white)
        .cornerRadius(6.0)
        .padding(.horizontal, 16.0)
    }
}

struct MessageView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.tangemBgGray
            VStack {
                MessageView(title: "Empty card", subtitle: "Create wallet to start using Tangem card", type: .error)
                MessageView(title: "Empty wallets", subtitle: "Wallet are empty", type: .message)
            }
        }
    }
}
