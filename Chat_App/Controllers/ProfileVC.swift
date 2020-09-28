//
//  ProfileVC.swift
//  Chat_App
//
//  Created by sa3doola on 9/12/20.
//  Copyright © 2020 saad sherif. All rights reserved.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit
import GoogleSignIn
import SDWebImage

class ProfileVC: UIViewController {
    
    @IBOutlet var tableView: UITableView!
    
    var data = [ProfileViewModel]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        data.append(ProfileViewModel(viewModeltype: .info,
                                     title: "Name: \(UserDefaults.standard.value(forKey: "name") as? String ?? "No Name")",
            handler: nil))
        data.append(ProfileViewModel(viewModeltype: .info,
                                     title: "Email: \(UserDefaults.standard.value(forKey: "email") as? String ?? "No Email")",
            handler: nil))
        data.append(ProfileViewModel(viewModeltype: .logout, title: "Log Out", handler: { [weak self] in
            
            guard let strongSelf = self else {
                return
            }
            
            let actionSheet = UIAlertController(title: "",
                                                message: "",
                                                preferredStyle: .actionSheet)
            actionSheet.addAction(UIAlertAction(title: "Log out",
                                                style: .destructive,
                                                handler: { [weak self] _ in
                                                    
                                                    guard let strongSelf = self else {
                                                        return
                                                    }
                                                    
                                                    // Log Out Facebook
                                                    FBSDKLoginKit.LoginManager().logOut()
                                                    
                                                    // Googel Log out
                                                    GIDSignIn.sharedInstance()?.signOut()
                                                    
                                                    do {
                                                        try FirebaseAuth.Auth.auth().signOut()
                                                        let vc = LoginVC()
                                                        let nav = UINavigationController(rootViewController: vc)
                                                        nav.modalPresentationStyle = .fullScreen
                                                        strongSelf.present(nav, animated: true)
                                                    }
                                                    catch {
                                                        print("Falied to log out")
                                                    }
                                                    
            }))
            actionSheet.addAction(UIAlertAction(title: "Cancel",
                                                style: .cancel,
                                                handler: nil))
            
            strongSelf.present(actionSheet, animated: true)
        }))
        
        tableView.register(ProfileTVC.self, forCellReuseIdentifier: ProfileTVC.id)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableHeaderView = createTableHeader()
    }
    
    func createTableHeader() -> UIView? {
        
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        let fileName = safeEmail + "_profile_picture.png"
        
        let path = "images/" + fileName
        
        let headerView = UIView(frame: CGRect(x: 0,
                                              y: 0,
                                              width: self.view.width,
                                              height: 300))
        headerView.backgroundColor = .link
        
        let imageView = UIImageView(frame: CGRect(x: (headerView.width-150) / 2,
                                                  y: 75,
                                                  width: 150,
                                                  height: 150))
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .white
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.layer.borderWidth = 3
        imageView.layer.cornerRadius = imageView.width/2
        imageView.layer.masksToBounds = true
        headerView.addSubview(imageView)
        
        StorageManager.shared.downloadURL(for: path) { (result) in
            switch result {
            case .success(let url):
                imageView.sd_setImage(with: url, completed: nil)
            case .failure(let error):
                print("Failed to get download Url: \(error)")
            }
        }
        
        return headerView
    }
}

extension ProfileVC: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let viewModel = data[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: ProfileTVC.id,
                                                 for: indexPath) as! ProfileTVC
        cell.setUp(with: viewModel)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        data[indexPath.row].handler?()
    }
}
