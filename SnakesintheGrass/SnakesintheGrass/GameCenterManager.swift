import SwiftUI
import GameKit

class GameCenterManager: NSObject, GKGameCenterControllerDelegate, ObservableObject {
    static let shared = GameCenterManager()
    let bestScoreLeaderboardID = "555"



    func authenticatePlayer() {
        let localPlayer = GKLocalPlayer.local
        localPlayer.authenticateHandler = { viewController, error in
            if let viewController = viewController {
                // Present authentication view controller
                if let rootViewController = UIApplication.shared.windows.first?.rootViewController {
                    rootViewController.present(viewController, animated: true)
                }
            } else if localPlayer.isAuthenticated {
                print("Player authenticated")
            } else {
                print("Player not authenticated")
                if let error = error {
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    func submitScore(_ score: Int) {
        if GKLocalPlayer.local.isAuthenticated {
            let scoreReporter = GKScore(leaderboardIdentifier: bestScoreLeaderboardID)
            scoreReporter.value = Int64(score)
            GKScore.report([scoreReporter]) { error in
                if let error = error {
                    print("Error submitting score: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func showLeaderboard() {
        if GKLocalPlayer.local.isAuthenticated {
            let gcViewController = GKGameCenterViewController(state: .leaderboards)
            gcViewController.gameCenterDelegate = self
            if let rootViewController = UIApplication.shared.windows.first?.rootViewController {
                rootViewController.present(gcViewController, animated: true)
            }
        }
    }
    
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true)
    }

    
}
