//
//  Route.swift
//  AssetLens
//
//  Created by Tarlan Ismayilsoy on 16.08.25.
//

enum Route: Hashable {
    case analysis(viewModel: AnalysisViewModel)
    
    var id: String { String(describing: self) }
    
    static func == (lhs: Route, rhs: Route) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
