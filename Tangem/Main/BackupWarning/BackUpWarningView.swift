//
//  BackUpWarningView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct BackUpWarningView: View {
    let tapAction: () -> ()
    
    var body: some View {
        Button {
            tapAction()
        } label: {
            HStack(alignment: .center, spacing: 0) {
                Image("warningIcon")
                    .padding(.vertical, 8)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("main_no_backup_warning_title".localized)
                        .fixedSize(horizontal: false, vertical: true)
                        .font(.system(size: 15, weight: .medium))
                        .padding(.leading, 10)
                    
                    Text("main_no_backup_warning_subtitle".localized)
                        .fixedSize(horizontal: false, vertical: true)
                        .font(.system(size: 13, weight: .regular))
                        .padding(.leading, 10)
                }
                
                Spacer()
                
                Image("chevron")
                    .padding(.trailing, 16)
                
            }
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.leading, 16)
        .padding(.vertical, 10)
        .background(Color.white)
        .contentShape(Rectangle())
    }
}

struct BackUpWarningView_Previews: PreviewProvider {
    static var previews: some View {
        BackUpWarningView(tapAction: { })
    }
}
