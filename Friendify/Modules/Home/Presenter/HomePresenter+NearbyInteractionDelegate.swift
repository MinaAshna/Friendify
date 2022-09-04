//
//  HomePresenter+NearbyInteractionDelegate.swift
//  Friendify
//
//  Created by Mina Ashna on 02/08/2022.
//

import Foundation
import NearbyInteraction

extension HomePresenter: NearbyInteractionDelegate {
    func sessionSuspentionEnded(_ session: NISession) {
        print("NISession suspention ended.")
        viewModel.logs.append("NISession suspention ended.")

        if let config = session.configuration {
            session.run(config)
        } else {
            startup(session: session)
        }
    }

    func sessionInvalidated(_ session: NISession) {
        print("NISession Invalidated.")
        viewModel.logs.append("NISession Invalidated.")
        viewModel.currentDistanceDirectionState = .unknown

        startup(session: session)
    }

    func sessionIsSuspended(_ session: NISession) {
        viewModel.currentDistanceDirectionState = .unknown
    }

    func sessionDidRemoveObject(_ session: NISession) {
        print("NISession did remove object.")
        viewModel.logs.append("NISession did remove object.")
        viewModel.currentDistanceDirectionState = .unknown

        startup(session: session)
    }

    func sessionDistanceToPeerUpdated(_ session: NISession, _ obj: NINearbyObject) {
        self.updateDistanceToPeer(session, nearbyObject: obj)
    }
}
