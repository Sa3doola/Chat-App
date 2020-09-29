//
//  Models.swift
//  Chat_App
//
//  Created by sa3doola on 9/24/20.
//  Copyright © 2020 saad sherif. All rights reserved.
//

import Foundation

struct ChatAppUser {
    
    let firstName: String
    let lastName: String
    let emailAddress: String
    
    var safeEmail: String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    
    var profilePictureFileName: String {
        // /images/saadsheri02-gmail-com_profile_picture.png
        return "\(safeEmail)_profile_picture.png"
    }
}
struct SearchResult {
    let name: String
    let email: String
}

enum ProfileViewModelType {
    case info, logout
}

struct ProfileViewModel {
    let viewModeltype: ProfileViewModelType
    let title: String
    let handler: (() -> Void)?
}
