//
//  ViewModel.swift
//  Friendify
//
//  Created by Mina Ashna on 16/04/2022.
//

import Foundation

class ViewModel: ObservableObject {
    @Published var displayName: String = "Guest"
    @Published var connectedPeerDisplayName: String?
}
