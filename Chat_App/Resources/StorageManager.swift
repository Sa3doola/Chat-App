//
//  StorageManager.swift
//  Chat_App
//
//  Created by sa3doola on 9/17/20.
//  Copyright © 2020 saad sherif. All rights reserved.
//

import Foundation
import FirebaseStorage

final class StorageManager {
    
    static let shared = StorageManager()
    
    private let storage = Storage.storage().reference()
    
    /*
     /images/saadsheri02-gmail-com_profile_picture.png
     */
    
    public typealias UploadPictureCompletion = (Result<String, Error>) -> Void
    public typealias DownloadPictureCompletion = (Result<URL, Error>) -> Void
    
    /// Uploads picture to Firebase Storage and return completion with url string to download
    public func uploadProfilePicture(with data: Data, fileName: String, completion: @escaping UploadPictureCompletion) {
        storage.child("images/\(fileName)").putData(data, metadata: nil, completion: { metadata, error in
            guard error == nil else {
                // failed
                print("Failed to upload data to firebase for picture")
                completion(.failure(StorageError.failedToUpload))
                return
            }
            
            self.storage.child("images/\(fileName)").downloadURL { (url, error) in
                guard let url = url else {
                    print("failed to get download url")
                    completion(.failure(StorageError.failedToGetDownloadURL))
                    return
                }
                
                let urlSting = url.absoluteString
                print("Download url returned: \(urlSting)")
                completion(.success(urlSting))
            }
        })
    }
    
    public func downloadURL(for path: String, completion: @escaping DownloadPictureCompletion) {
        let referenc = storage.child(path)
        
        referenc.downloadURL { (url, error) in
            guard let url = url, error == nil else {
                completion(.failure(StorageError.failedToGetDownloadURL))
                return
            }
            
            completion(.success(url))
        }
    }
    
    /// Upload image that will be send to conversation message
    public func uploadMessagePhoto(with data: Data, fileName: String, completion: @escaping  UploadPictureCompletion) {
        storage.child("message_images/\(fileName)").putData(data, metadata: nil, completion: { [weak self] metadata, error in
            guard error == nil else {
                // failed
                print("Failed to upload data to firebase for picture")
                completion(.failure(StorageError.failedToUpload))
                return
            }
            
            self?.storage.child("message_images/\(fileName)").downloadURL { (url, error) in
                guard let url = url else {
                    print("failed to get download url")
                    completion(.failure(StorageError.failedToGetDownloadURL))
                    return
                }
                
                let urlSting = url.absoluteString
                print("Download url returned: \(urlSting)")
                completion(.success(urlSting))
            }
        })
    }
    
    /// Upload Video that will be send to conversation message
    public func uploadMessageVideo(with fileUrl: URL, fileName: String, completion: @escaping  UploadPictureCompletion) {
        storage.child("message_images/\(fileName)").putFile(from: fileUrl, metadata: nil) { [weak self] (metaData, error) in
            
            guard error == nil else {
                // failed
                print("Failed to upload video file to firebase for video")
                completion(.failure(StorageError.failedToUpload))
                return
            }
            
            self?.storage.child("message_videos/\(fileName)").downloadURL { (url, error) in
                guard let url = url else {
                    print("failed to get download url")
                    completion(.failure(StorageError.failedToGetDownloadURL))
                    return
                }
                
                let urlSting = url.absoluteString
                print("Download url returned: \(urlSting)")
                completion(.success(urlSting))
            }
        }
    }
    
    public enum StorageError: Error {
        case failedToUpload
        case failedToGetDownloadURL
    }
    
}
