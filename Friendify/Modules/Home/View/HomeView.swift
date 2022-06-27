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
    var presenter: HomePresenterProtocol

    var body: some View {
        NavigationView {
            VStack {
                Text("Hi \(viewModel.displayName)")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                Text(viewModel.sessionState.rawValue)
                if let distance = viewModel.distanceToPeer {
                    Text(String(format: "%0.2f", distance))
                }
                Text(viewModel.azimuthDirection?.rawValue ?? "Direction is not available")
                Text(viewModel.elevationDirection?.rawValue ?? "Direction is not available")

                Image(systemName: "arrow.up")
                    .resizable()
                    .frame(width: 60, height: 80, alignment: .center)
                    .padding()
                    .rotationEffect(Angle(radians: viewModel.rotationAngle))
                    .opacity(viewModel.sessionState == .notConnected ? 0 : 1)

                Spacer()

                Button {
                    presenter.mingleButtonPressed()
                } label: {
                    Text(viewModel.sessionState == .notConnected ? "Let's Mingle :)" : "Cancel")
                        .font(.title3)
                        .foregroundColor(colorScheme == .dark ? .black : .white)
                        .frame(height: 45)
                        .padding()
                        .background(Color.primary)
                        .cornerRadius(8)
                }
                .opacity(viewModel.sessionState == .notConnected ? 1 : 0)
                .padding()

                List {
                    ForEach(viewModel.logs, id: \.self) { log in
                        Text(log)
                    }
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    class DummyPresenter: HomePresenterProtocol {
        func mingleButtonPressed() {

        }
    }

    static var previews: some View {
        let viewModel = AppViewModel()
        let presenter = DummyPresenter()

        HomeView(viewModel: viewModel, presenter: presenter)
            .preferredColorScheme(.dark)

        HomeView(viewModel: viewModel, presenter: presenter)
            .preferredColorScheme(.light)
    }
}
