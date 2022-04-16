//
//  ViewModel.swift
//  Friendify
//
//  Created by Mina Ashna on 16/04/2022.
//

import Foundation

class ViewModel: ObservableObject {
    var displayName: String?
    @Published var connectedPeerDisplayName: String?
}
