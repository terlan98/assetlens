//
//  Router.swift
//  AssetLens
//
//  Created by Tarlan Ismayilsoy on 16.08.25.
//

import SwiftUI

@MainActor
class Router: ObservableObject {
    @Published var path: NavigationPath = NavigationPath()
    static let shared: Router = Router()
    private init() {}
    
    func push(_ route: Route) {
        path.append(route)
    }
    
    func pop() {
        path.removeLast()
    }
    
    func destination(for route: Route) -> some View {
        Group {
            switch route {
            case .analysis(let viewModel):
                AnalysisView(viewModel)
            case .groups(let viewModel):
                GroupsView(viewModel)
            }
        }
    }
}
