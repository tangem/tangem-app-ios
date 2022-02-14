//
//  BackupStoryPage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct BackupStoryPage: View {
    var body: some View {
        VStack {
            Text("story_backup_title")
                .multilineTextAlignment(.center)
            
            Text("story_backup_description")
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
            Spacer()
            

            Image(systemName: "person")
            
            Spacer()
            
            HStack {
                Text("Scan Card")
                
                Text("Order Card")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct BackupStoryPage_Previews: PreviewProvider {
    static var previews: some View {
        BackupStoryPage()
    }
}
