//
//  BackUpWarningView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct BackUpWarningButton: View {
    let tapAction: () -> ()

    var body: some View {
        Button {
            tapAction()
        } label: {
            HStack(alignment: .center, spacing: 0) {
                Image("warningIcon")
                    .frame(width: 42, height: 42)
                    .background(Color.tangemBgGray)
                    .cornerRadius(21)
                    .padding(.vertical, 8)

                VStack(alignment: .leading, spacing: 2) {
                    Text(Localization.mainNoBackupWarningTitle)
                        .font(.system(size: 15, weight: .medium))

                    Text(Localization.mainNoBackupWarningSubtitle)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(Color.tangemTextGray)
                }
                .fixedSize(horizontal: false, vertical: true)
                .padding(.leading, 10)

                Spacer()

                Image("chevron")
            }
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.white)
        .contentShape(Rectangle())
        .cornerRadius(16)
    }
}

struct BackUpWarningView_Previews: PreviewProvider {
    static var previews: some View {
        BackUpWarningButton(tapAction: { })
    }
}
