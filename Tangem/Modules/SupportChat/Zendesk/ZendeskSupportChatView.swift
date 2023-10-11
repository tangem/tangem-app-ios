//
//  ZendeskSupportChatView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import UIKit
import SwiftUI

/*
 🚨🚨🚨

 Are you removing Zendesk? READ BELOW:

 🦄🦄🦄

 Zendesk and Sprinklr are displayed as a sheet and full screen cover respectively
 Make sure to remove all the hacks related to this discrepancy.
 Also make sure to clean up the code in AppPresenter.showSupportChat

 ⚠️⚠️⚠️
 */

struct ZendeskSupportChatView: UIViewControllerRepresentable {
    let viewModel: ZendeskSupportChatViewModel

    func makeUIViewController(context: Context) -> UIViewController {
        guard let viewController = try? viewModel.buildUI() else {
            return UINavigationController(rootViewController: UIViewController(nibName: nil, bundle: nil))
        }
        return UINavigationController(rootViewController: viewController)
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
}
