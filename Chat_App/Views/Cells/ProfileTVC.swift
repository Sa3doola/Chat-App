//
//  ProfileTVC.swift
//  Chat_App
//
//  Created by sa3doola on 9/28/20.
//  Copyright © 2020 saad sherif. All rights reserved.
//

import UIKit

class ProfileTVC: UITableViewCell {
    
    static let id = "ProfileTVC"

    public func setUp(with viewModel: ProfileViewModel) {
        textLabel?.text = viewModel.title
        switch viewModel.viewModeltype {
        case .info:
            textLabel?.textAlignment = .left
            selectionStyle = .none
        case .logout:
            textLabel?.textColor = .red
            textLabel?.textAlignment = .center
        }
    }
}
