//
//  DatabaseManager.swift
//  Chat_App
//
//  Created by sa3doola on 9/15/20.
//  Copyright © 2020 saad sherif. All rights reserved.
//

import Foundation
import FirebaseDatabase
import MessageKit
import CoreLocation

/// Manager object to read and write data to real time firebase database
final class DatabaseManager {
    
    /// Shared instance of class
    static let shared = DatabaseManager()
    
    private let database = Database.database().reference()
    
    public typealias getAllUsersCompletion = (Result<[[String: String]], Error>) -> Void
    public typealias getAllConversationCompletion = (Result<[Conversation], Error>) -> Void
    public typealias getAllMessagesCompletion = (Result<[Message], Error>) -> Void
    
    static func safeEmail(emailAddress: String) -> String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    
}

extension DatabaseManager {
    
    /// Return dictionary node at child path
    public func getDataFor(path: String, completion: @escaping (Result<Any, Error>) -> Void) {
        database.child("\(path)").observeSingleEvent(of: .value) { (snapshot) in
            guard let value = snapshot.value else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            completion(.success(value))
        }
    }
}

//MARK: - Account Management

extension DatabaseManager {
    
    /// Check if user exists for given user email
    /// Parameters
    /// - email:            Target email to be checked
    /// - completion:    Async closure to return with result
    public func userExists(with email: String, completion: @escaping ((Bool) -> Void)) {
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        
        database.child(safeEmail).observeSingleEvent(of: .value) { (snapShot) in
            guard snapShot.value as? [String: Any] != nil else {
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
            ], withCompletionBlock: { [weak self] error, _ in
                
                guard let strongSelf = self else {
                    return
                }
                
                guard error == nil else {
                    print("Failed to write to database")
                    completion(false)
                    return
                }
                
                strongSelf.database.child("Users").observeSingleEvent(of: .value, with: { snapshot in
                    if var usersCollection = snapshot.value as? [[String: String]] {
                        // append to user dictionary
                        let newElemebt = [
                            "name": user.firstName + " " + user.lastName,
                            "email": user.safeEmail
                        ]
                        usersCollection.append(newElemebt)
                        
                        strongSelf.database.child("Users").setValue(usersCollection, withCompletionBlock: { error, _ in
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
                        
                        strongSelf.database.child("Users").setValue(newCollection, withCompletionBlock: { error, _ in
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
    
    /// Gets all users from databse
    public func getAllUsers(completion: @escaping getAllUsersCompletion) {
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
        
        public var localizedDescription: String {
            switch self {
            case .failedToFetch:
                return "This means balh failed"
            }
        }
    }
}

//MARK: - Sending messages / Conversations

extension DatabaseManager {
    
    /// Create a new conversation with target user email and first message sent
    public func createNewConversation(with otherUserEmail: String, name: String, firstMessage: Message, completion: @escaping (Bool) -> Void) {
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String,
            let currentName = UserDefaults.standard.value(forKey: "name") as? String else {
                return
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentEmail)
        
        let ref = database.child("\(safeEmail)")
        
        ref.observeSingleEvent(of: .value, with: { [weak self] snapshot in
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
            
            let recipient_newConversation: [String: Any] = [
                "id": conversationID,
                "other_user_email": safeEmail,
                "name": currentName,
                "latest_message": [
                    "date": dateString,
                    "message": message,
                    "is_read": false
                ]
            ]
            
            // Update rescipient conversation entry
            self?.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value, with: { [weak self] snapshot in
                if var conversations = snapshot.value as? [[String: Any]] {
                    // append
                    conversations.append(recipient_newConversation)
                    self?.database.child("\(otherUserEmail)/conversations").setValue([conversations])
                }
                else {
                    // create
                    self?.database.child("\(otherUserEmail)/conversations").setValue([recipient_newConversation])
                }
            })
            
            // Update other user conversation entry
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
    public func getAllConversations(for email: String, completion: @escaping getAllConversationCompletion) {
        
        database.child("\(email)/conversations").observe(.value, with: { snapshot in
            guard let value = snapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            let conversations: [Conversation] = value.compactMap({ dictionary in
                guard let conversationID = dictionary["id"] as? String,
                    let name = dictionary["name"] as? String,
                    let otherUserEmail = dictionary["other_user_email"] as? String,
                    let latestMessage = dictionary["latest_message"] as? [String: Any],
                    let date = latestMessage["date"] as? String,
                    let message = latestMessage["message"] as? String,
                    let isRead = latestMessage["is_read"] as? Bool else {
                        return nil
                }
                
                let latestMessageObject = LatestMessage(date: date, text: message, isRead: isRead)
                
                return Conversation(id: conversationID, name: name, otherUserEmail: otherUserEmail, latestMessage: latestMessageObject)
            })
            completion(.success(conversations))
        })
    }
    
    /// Gets all Messages for given conversation
    public func getAllMessagesForConversations(with id: String, completion: @escaping getAllMessagesCompletion) {
        
        database.child("\(id)/messages").observe(.value, with: { snapshot in
            guard let value = snapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                print("failed y m3lemy")
                return
            }
            
            let messages: [Message] = value.compactMap({ dictionary in
                guard let messageID = dictionary["id"] as? String,
                    let name = dictionary["name"] as? String,
                    let senderEmail = dictionary["sender_email"] as? String,
                    let date = dictionary["date"] as? String,
                    let type = dictionary["type"] as? String,
                    let content = dictionary["content"] as? String,
                    let dateSring = ChatVC.dateFormatter.date(from: date)
                    else {
                        return nil
                }
                var kind: MessageKind?
                if type == "photo" {
                    // photo
                    guard let imageUrl = URL(string: content),
                        let placeHolder = UIImage(systemName: "plus") else {
                            return nil
                    }
                    let media = Media(url: imageUrl,
                                      image: nil,
                                      placeholderImage: placeHolder,
                                      size: CGSize(width: 300, height: 300))
                    kind = .photo(media)
                }
                else if type == "video" {
                    // photo
                    guard let videoUrl = URL(string: content),
                        let placeHolder = UIImage(systemName: "plus") else {
                            return nil
                    }
                    let media = Media(url: videoUrl,
                                      image: nil,
                                      placeholderImage: placeHolder,
                                      size: CGSize(width: 300, height: 300))
                    kind = .photo(media)
                }
                else if type == "location" {
                    let locationComponents = content.components(separatedBy: ",")
                    guard let longitude = Double(locationComponents[0]),
                        let latitude = Double(locationComponents[1]) else {
                            return nil
                    }
                    
                    print("Rendering location: long=\(longitude) | lat= \(latitude)")
                    
                    let location = Location(location: CLLocation(latitude: latitude, longitude: longitude),
                                            size: CGSize(width: 300, height: 300))
                    kind = .location(location)
                }
                else {
                    // text
                    kind = .text(content)
                }
                
                guard let finalKind = kind else {
                    return nil
                }
                
                
                let sender = Sender(photoURL: "", senderId: senderEmail, displayName: name)
                
                return Message(sender: sender,
                               messageId: messageID,
                               sentDate: dateSring,
                               kind:  finalKind)
                
            })
            
            completion(.success(messages))
        })
        
    }
    
    /// Send message with target conversation and message
    public func sendMessage(to conversationID: String, otherUserEmail: String, name: String, newMessage: Message, completion: @escaping (Bool) -> Void) {
        // add new message to messsages
        // update senedr latest message
        // update recipient latest message
        
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        
        let currentEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
        
        database.child("\(conversationID)/messages").observeSingleEvent(of: .value) { [weak self] (snapshot) in
            guard let strongSelf = self else {
                return
            }
            
            guard var currentMessages = snapshot.value as? [[String: Any]] else {
                completion(false)
                return
            }
            let messageDate = newMessage.sentDate
            let dateString = ChatVC.dateFormatter.string(from: messageDate)
            
            var message = ""
            switch newMessage.kind {
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(let mediaItem):
                if let targetUrlString = mediaItem.url?.absoluteString {
                    message = targetUrlString
                }
                break
            case .video(let mediaItem):
                if let targetUrlString = mediaItem.url?.absoluteString {
                    message = targetUrlString
                }
                break
            case .location(let locationData):
                let location = locationData.location
                message = "\(location.coordinate.longitude),\(location.coordinate.latitude)"
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
            
            let newMessageEntry: [String: Any] = [
                "id": newMessage.messageId,
                "type": newMessage.kind.messageKindString,
                "content": message,
                "date": dateString,
                "sender_email": currentUserEmail,
                "is_read": false,
                "name": name
            ]
            
            currentMessages.append(newMessageEntry)
            
            strongSelf.database.child("\(conversationID)/messages").setValue(currentMessages) { (error, _) in
                guard error == nil else {
                    completion(false)
                    return
                }
                
                strongSelf.database.child("\(currentEmail)/conversations").observeSingleEvent(of: .value) { (snapshot) in
                    var databaseEntryConversations = [[String: Any]]()
                    let updatedValue: [String: Any] = [
                        "date": dateString,
                        "is_read": false,
                        "message": message
                    ]
                    
                    if var currentUserConversation = snapshot.value as? [[String: Any]] {
                        // we need to create conversation entry
                        var targetConversation: [String: Any]?
                        var postion = 0
                        
                        for conversationDictionary in currentUserConversation {
                            if let currentID = conversationDictionary["id"] as? String, currentID == conversationID {
                                targetConversation = conversationDictionary
                                break
                            }
                            postion += 1
                        }
                        
                        if var targetConversation = targetConversation {
                            targetConversation["latest_message"] = updatedValue
                            currentUserConversation[postion] = targetConversation
                            databaseEntryConversations = currentUserConversation
                        }
                        else {
                            let newConversation: [String: Any] = [
                                "id": conversationID,
                                "other_user_email": DatabaseManager.safeEmail(emailAddress: otherUserEmail),
                                "name": name,
                                "latest_message": [
                                    updatedValue
                                ]
                            ]
                            currentUserConversation.append(newConversation)
                            databaseEntryConversations = currentUserConversation
                        }
                    }
                    else {
                        let newConversation: [String: Any] = [
                            "id": conversationID,
                            "other_user_email": DatabaseManager.safeEmail(emailAddress: otherUserEmail),
                            "name": name,
                            "latest_message": [
                                updatedValue
                            ]
                        ]
                        databaseEntryConversations = [
                            newConversation
                        ]
                    }
                    
                    strongSelf.database.child("\(currentEmail)/conversations").setValue(databaseEntryConversations) { (error, _) in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        
                        // update latest message for recipient user
                        strongSelf.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value) { (snapshot) in
                            var databaseEntryConversations = [[String: Any]]()
                            let updatedValue: [String: Any] = [
                                "date": dateString,
                                "is_read": false,
                                "message": message
                            ]
                            guard let currentName = UserDefaults.standard.value(forKey: "name") as? String else {
                                return
                            }
                            
                            if var otherUserConversation = snapshot.value as? [[String: Any]] {
                                var targetConversation: [String: Any]?
                                var postion = 0
                                
                                for conversationDictionary in otherUserConversation {
                                    if let currentID = conversationDictionary["id"] as? String, currentID == conversationID {
                                        targetConversation = conversationDictionary
                                        break
                                    }
                                    postion += 1
                                }
                                if var targetConversation = targetConversation {
                                    targetConversation["latest_message"] = updatedValue
                                    otherUserConversation[postion] = targetConversation
                                    databaseEntryConversations = otherUserConversation
                                }
                                else {
                                    // failed to find in current collection
                                    let newConversation: [String: Any] = [
                                        "id": conversationID,
                                        "other_user_email": DatabaseManager.safeEmail(emailAddress: currentEmail),
                                        "name": currentName,
                                        "latest_message": [
                                            updatedValue
                                        ]
                                    ]
                                    otherUserConversation.append(newConversation)
                                    databaseEntryConversations = otherUserConversation
                                }
                            }
                            else {
                                // current collection does not exists
                                let newConversation: [String: Any] = [
                                    "id": conversationID,
                                    "other_user_email": DatabaseManager.safeEmail(emailAddress: currentEmail),
                                    "name": currentName,
                                    "latest_message": [
                                        updatedValue
                                    ]
                                ]
                                databaseEntryConversations = [
                                    newConversation
                                ]
                            }
                            
                            strongSelf.database.child("\(otherUserEmail)/conversations").setValue(databaseEntryConversations) { (error, _) in
                                guard error == nil else {
                                    completion(false)
                                    return
                                }
                                completion(true)
                            }
                        }
                    }
                }
            }
        }
    }
    
    public func deleteConversation(conversationID: String, completion: @escaping (Bool) -> Void) {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        
        print("Deleting conversation with id: \(conversationID)")
        
        // Get all conversation for current user
        // delete conversation in collection with target id
        // reset those conversaion for the user in database
        let ref = database.child("\(safeEmail)/conversations")
        ref.observeSingleEvent(of: .value) { (snapshot) in
            if var conversations = snapshot.value as? [[String: Any]] {
                var postionToRemove = 0
                for conversation in conversations {
                    if let id = conversation["id"] as? String,
                        id == conversationID {
                        print("found conversation to delete")
                        break
                    }
                    postionToRemove += 1
                }
                
                conversations.remove(at: postionToRemove)
                ref.setValue(conversations, withCompletionBlock: { error, _ in
                    guard error == nil else {
                        completion(false)
                        print("failed to write new conversation array")
                        return
                    }
                    print("delete conversation")
                    completion(true)
                })
            }
        }
    }
    
    
    public func conversationExists(with targetRecipientEmail: String, completion: @escaping (Result<String, Error>) -> Void) {
        
        let safeRecipientEmail = DatabaseManager.safeEmail(emailAddress: targetRecipientEmail)
        guard let senderEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let safeSenderEmail = DatabaseManager.safeEmail(emailAddress: senderEmail)
        
        database.child("\(safeRecipientEmail)/conversations").observeSingleEvent(of: .value) { (snapshot) in
            guard let collection = snapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            // iterate and find conversation with target sender
            if let conversation = collection.first(where: {
                guard let targetSenderEmail = $0["other_user_email"] as? String else {
                    return false
                }
                return safeSenderEmail == targetSenderEmail
            }) {
                // get id
                guard let id = conversation["id"] as? String else {
                    completion(.failure(DatabaseError.failedToFetch))
                    return
                }
                completion(.success(id))
                return
            }
            completion(.failure(DatabaseError.failedToFetch))
            return
        }
    }
}


