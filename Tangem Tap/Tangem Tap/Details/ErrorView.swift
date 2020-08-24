//
//  NoAccountView.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemSdk

struct ErrorView: View {
    var title: String
    var subtitle: String
    
    var body: some View {
        HStack(alignment: .titleAndExclamation, spacing: 18.0) {
            Spacer()
                .frame(width: 8.0, height: nil, alignment: .center)
                Image("exclamationmark.circle")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(Color.tangemTapYellow)
                    .frame(width: 26.5, height: 26.5)
                    .alignmentGuide(.titleAndExclamation) { d in d[.bottom] / 2 }

            VStack(alignment: .leading, spacing: 6.0) {
                Text(title)
                    .font(Font.system(size: 20.0))
                    .fontWeight(.bold)
                    .multilineTextAlignment(.leading)
                    .lineLimit(1)
                    .alignmentGuide(.titleAndExclamation) { d in d[.bottom] / 2 }
                    .foregroundColor(Color.tangemTapTitle)
                Text(subtitle)
                    .font(Font.system(size: 11.0))
                    .fontWeight(.medium)
                    .foregroundColor(Color.tangemTapDarkGrey)
                    .multilineTextAlignment(.leading)
                    .lineLimit(1)
            }
            .padding(.vertical, 16.0)
            Spacer()
        }
        .background(Color.white)
        .cornerRadius(6.0)
        .padding(.horizontal, 16.0)
    }
}

struct ErrorView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.tangemTapBgGray
            ErrorView(title: "Empty card", subtitle: "Create wallet to start using Tangem card")
        }
    }
}

extension VerticalAlignment {
    private enum TitltAndExclamation: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            return context[.bottom]
        }
    }
    
    static let titleAndExclamation = VerticalAlignment(TitltAndExclamation.self)
}
