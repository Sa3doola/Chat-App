//
//  Models.swift
//  Chat_App
//
//  Created by sa3doola on 9/24/20.
//  Copyright © 2020 saad sherif. All rights reserved.
//

import Foundation
import MessageKit
import CoreLocation

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

struct Conversation {
    let id: String
    let name: String
    let otherUserEmail: String
    let latestMessage: LatestMessage
}

struct LatestMessage {
    let date: String
    let text: String
    let isRead: Bool
}

struct SearchResult {
    let name: String
    let email: String
}

struct Message: MessageType {
    var sender: SenderType
    var messageId: String
    var sentDate: Date
    var kind: MessageKind
}

extension MessageKind {
    var messageKindString: String {
        switch self {
        case .text(_):
            return "text"
        case .attributedText(_):
            return "attributed_text"
        case .photo(_):
            return "photo"
        case .video(_):
            return "video"
        case .location(_):
            return "location"
        case .emoji(_):
            return "emoji"
        case .audio(_):
            return "audio"
        case .contact(_):
            return "contact"
        case .linkPreview(_):
            return "linkPreview"
        case .custom(_):
            return "custom"
        }
    }
}

struct Media: MediaItem {
    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage
    var size: CGSize
}

struct Sender: SenderType {
    var photoURL: String
    var senderId: String
    var displayName: String
}

struct Location: LocationItem {
    var location: CLLocation
    var size: CGSize
}

enum ProfileViewModelType {
    case info, logout
}

struct ProfileViewModel {
    let viewModeltype: ProfileViewModelType
    let title: String
    let handler: (() -> Void)?
}
