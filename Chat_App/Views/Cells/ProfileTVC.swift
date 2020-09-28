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
        self.textLabel?.text = viewModel.title
        switch viewModel.viewModeltype {
        case .info:
            self.textLabel?.textAlignment = .left
            self.selectionStyle = .none
        case .logout:
            self.textLabel?.textColor = .red
            self.textLabel?.textAlignment = .center
        }
    }
}
