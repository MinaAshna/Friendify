//
//  HomeView.swift
//  Friendify
//
//  Created by Mina Ashna on 16/04/2022.
//

import SwiftUI

struct HomeView: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var viewModel: AppViewModel
    private var buttonText: String {
        switch viewModel.sessionState {
        case .notConnected:
            return "Let's Connect"
        case .peerConnected:
            return "Share my Position"
        default:
            return ""
        }
    }
    var presenter: HomePresenterProtocol
    @State private var presentAlert = false
    
    var body: some View {
        GeometryReader { reader in
            VStack {
                Text("Hi \(viewModel.myObject.displayName)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top, 16)
                
                Spacer()
                
                HStack(alignment: .top) {
                    if viewModel.sessionState == .peerConnected, let peer = viewModel.myObject.connectedPeer?.displayName {
                        Text(viewModel.sessionState.rawValue + " to " + peer)
                    } else
                    if viewModel.sessionState != .notConnected {
                        Text(viewModel.sessionState.rawValue)
                        
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 8) {
                        if let distance = viewModel.myObject.distanceToPeer {
                            Text(String(format: "%0.2f", distance))
                        }
                        if let direction = viewModel.azimuthDirection {
                            Text(direction.rawValue)
                        }
                    }
                }
                .padding(16)
                
                Divider()
                
                Spacer()

                List {
                    ForEach(viewModel.chat, id: \.self) { message in
                        Text(message)
                    }
                }
                .opacity(viewModel.sessionState == .notConnected ? 0 : 1)
                
                HStack {
                    TextField("Message", text: $viewModel.message)
                        .padding(8)
                        .frame(height: 60)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.primary,
                                        lineWidth: 0.5)
                                .frame(height: 60)
                        )
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Button {
                        presenter.sendMessage()
                    } label: {
                        Text("Send")
                            .foregroundColor(.primary)
                    }
                }
                .padding(16)
                .opacity(viewModel.sessionState == .peerConnected || viewModel.sessionState == .peerConnectedAndPositionShared ? 1 : 0)
                

                
                Button {
                    presenter.connectButtonTapped()
                    if viewModel.sessionState == .peerConnected {
                        presentAlert = !viewModel.isNearbyInteractionSupported
                    }
                } label: {
                    Text(buttonText)
                        .font(.title3)
                        .foregroundColor(colorScheme == .dark ? .black : .white)
                        .frame(width: reader.size.width * 0.9, height: viewModel.sessionState == .notConnected || viewModel.sessionState == .peerConnected ? 60 : 0)
                        .background(Color.primary)
                        .cornerRadius(8)
                }
                .padding()
                .alert("Oh Oh! Nearby Interaction is not supported.",
                       isPresented: $presentAlert) {
                    Button("OK", role: .cancel) { }
                }
            }
            
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    class DummyPresenter: HomePresenterProtocol {        
        func connectButtonTapped() { }
        func sendMessage() { }
    }

    static var viewModel: AppViewModel {
        let viewModel = AppViewModel()
        viewModel.sessionState = .peerConnected
        viewModel.myObject = Object()
        viewModel.myObject.displayName = "Mina"
        viewModel.myObject.distanceToPeer = 2.5
        viewModel.azimuthDirection = .left
        return viewModel
    }
    
    static var previews: some View {
        
        let presenter = DummyPresenter()

        HomeView(viewModel: HomeView_Previews.viewModel, presenter: presenter)
            .preferredColorScheme(.dark)

        HomeView(viewModel: HomeView_Previews.viewModel, presenter: presenter)
            .preferredColorScheme(.light)
    }
}
