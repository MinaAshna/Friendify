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

    var body: some View {
        NavigationView {
            VStack {
                Text("Hi \(viewModel.displayName)")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                Button {
                   
                } label: {
                    Text("Let's Mingle :)")
                        .font(.title3)
                        .foregroundColor(colorScheme == .dark ? .black : .white)
                        .frame(height: 45)
                        .padding()
                        .background(Color.primary)
                        .cornerRadius(8)
                }

                Spacer()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = AppViewModel()
        HomeView(viewModel: viewModel)
            .preferredColorScheme(.dark)

        HomeView(viewModel: viewModel)
            .preferredColorScheme(.light)
    }
}
