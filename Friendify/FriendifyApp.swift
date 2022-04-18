//
//  FriendifyApp.swift
//  Friendify
//
//  Created by Mina Ashna on 16/04/2022.
//

import SwiftUI

@main
struct FriendifyApp: App {
    var body: some Scene {
        WindowGroup {
            OnboardingView(viewModel: AppViewModel())
        }
    }
}
