//
//  DatabaseManager.swift
//  Chat_App
//
//  Created by sa3doola on 9/15/20.
//  Copyright © 2020 saad sherif. All rights reserved.
//

import Foundation
import FirebaseDatabase

final class DatabaseManager {
    
    static let shared = DatabaseManager()
    
    private let database = Database.database().reference()
    
    public typealias getAllUsers = (Result<[[String: String]], Error>) -> Void
    public typealias getAllConversation = (Result<[Conversation], Error>) -> Void
    
    static func safeEmail(emailAddress: String) -> String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    
    
}

//MARK: - Account Management

extension DatabaseManager {
    
    public func userExists(with email: String, completion: @escaping ((Bool) -> Void)) {
        
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        
        database.child(safeEmail).observeSingleEvent(of: .value) { (snapShot) in
            guard snapShot.value as? String != nil else {
                completion(false)
                return
            }
            completion(true)
        }
    }
    
    /// insert new user to database
    public func insertUser(with user: ChatAppUser, completion: @escaping (Bool) -> Void) {
        
        database.child(user.safeEmail).setValue([
            "first_name": user.firstName,
            "last_name": user.lastName
            ], withCompletionBlock: { error, _ in
                guard error == nil else {
                    print("Failed to write to database")
                    completion(false)
                    return
                }
                
                self.database.child("Users").observeSingleEvent(of: .value, with: { snapshot in
                    if var usersCollection = snapshot.value as? [[String: String]] {
                        // append to user dictionary
                        let newElemebt = [
                            "name": user.firstName + " " + user.lastName,
                            "email": user.safeEmail
                        ]
                        usersCollection.append(newElemebt)
                        
                        self.database.child("Users").setValue(usersCollection, withCompletionBlock: { error, _ in
                            guard error == nil else {
                                completion(false)
                                return
                            }
                            completion(true)
                        })
                    }
                    else {
                        // Create that array
                        let newCollection: [[String: String]] = [
                            [
                                "name": user.firstName + " " + user.lastName,
                                "email": user.safeEmail
                            ]
                        ]
                        
                        self.database.child("Users").setValue(newCollection, withCompletionBlock: { error, _ in
                            guard error == nil else {
                                completion(false)
                                return
                            }
                            completion(true)
                        })
                    }
                })
        })
    }
    
    public func getAllUsers(completion: @escaping getAllUsers) {
        database.child("Users").observeSingleEvent(of: .value) { (snapshot) in
            guard let value = snapshot.value as? [[String: String]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            completion(.success(value))
        }
    }
    
    public enum DatabaseError: Error {
        case failedToFetch
    }
}

//MARK: - Sending messages / Conversations

extension DatabaseManager {
    
    
    /// Create a new conversation with target user email and first message sent
    public func createNewConversation(with otherUserEmail: String, name: String, firstMessage: Message, completion: @escaping (Bool) -> Void) {
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentEmail)
        
        let ref = database.child("\(safeEmail)")
        
        ref.observeSingleEvent(of: .value, with: { snapshot in
            guard var userNode = snapshot.value as? [String: Any]  else {
                completion(false)
                print("User not found")
                return
            }
            
            let messageDate = firstMessage.sentDate
            let dateString = ChatVC.dateFormatter.string(from: messageDate)
            
            var message = ""
            
            switch firstMessage.kind {
                
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            
            let conversationID = "conversation_\(firstMessage.messageId)"
            
            let newConversation: [String: Any] = [
                "id": conversationID,
                "other_user_email": otherUserEmail,
                "name": name,
                "latest_message": [
                    "date": dateString,
                    "message": message,
                    "is_read": false
                ]
            ]
            if var conversations = userNode["conversations"] as? [[String: Any]] {
                // conversation array exists for current user
                // you should append
                conversations.append(newConversation)
                userNode["conversations"] = conversations
                ref.setValue(userNode, withCompletionBlock: { [weak self] error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self?.finishCreatingConversation(name: name, conversationID: conversationID, firstMessage: firstMessage, completion: completion)
                })
                
            }
            else {
                // Conversation array does not exist
                // Create it
                userNode["conversations"] = [
                    newConversation
                ]
                
                ref.setValue(userNode, withCompletionBlock: { [weak self] error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self?.finishCreatingConversation(name: name, conversationID: conversationID, firstMessage: firstMessage, completion: completion)
                })
            }
        })
    }
    
    private func finishCreatingConversation(name: String, conversationID: String, firstMessage: Message, completion: @escaping (Bool) -> Void) {
        
        let messageDate = firstMessage.sentDate
        let dateString = ChatVC.dateFormatter.string(from: messageDate)
        
        var message = ""
        
        switch firstMessage.kind {
            
        case .text(let messageText):
            message = messageText
        case .attributedText(_):
            break
        case .photo(_):
            break
        case .video(_):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .linkPreview(_):
            break
        case .custom(_):
            break
        }
        
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        
        let currentUserEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
        
        let collectionMessage: [String: Any] = [
            "id": firstMessage.messageId,
            "type": firstMessage.kind.messageKindString,
            "content": message,
            "date": dateString,
            "sender_email": currentUserEmail,
            "is_read": false,
            "name": name
        ]
        
        let value: [String: Any] = [
            "messages": [
                collectionMessage
            ]
        ]
        
        print("adding convo: \(conversationID)")
        
        database.child("\(conversationID)").setValue(value, withCompletionBlock: { error, _ in
            guard error == nil else {
                completion(false)
                return
            }
            completion(true)
        })
    }
    
    /// Fetches and return  all conversations for the user passed in email
    public func getAllConversations(for email: String, completion: @escaping getAllConversation) {
        
        database.child("\(email)/conversations").observe(.value, with: { snapshot in
            
        })
        
        
    }
    
    /// Get all Messages for given conversation
    public func getAllMessagesForConversations(with id: String, completion: @escaping getAllConversation) {
        
    }
    
    /// Send message with target conversation and message
    public func sendMessage(to conversation: String, message: Message, completion: @escaping (Bool) -> Void) {
        
    }
}



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
