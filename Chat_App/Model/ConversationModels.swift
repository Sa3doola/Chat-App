//
//  ConversationModels.swift
//  Chat_App
//
//  Created by sa3doola on 9/29/20.
//  Copyright © 2020 saad sherif. All rights reserved.
//

import Foundation

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
