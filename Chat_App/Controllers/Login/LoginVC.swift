//
//  LoginVC.swift
//  Chat_App
//
//  Created by sa3doola on 9/12/20.
//  Copyright © 2020 saad sherif. All rights reserved.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit
import GoogleSignIn
import JGProgressHUD

class LoginVC: UIViewController {
    
    private let spinner = JGProgressHUD(style: .dark)
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    private let LogoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "Logo")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let emailField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Email Address.."
        field.font = UIFont(name: "Avenir Next", size: 20)
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .white
        return field
    }()
    
    private let passwordField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .done
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Password.."
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .white
        field.isSecureTextEntry = true
        return field
    }()
    
    private let loginButton: UIButton = {
        let button = UIButton()
        button.setTitle("Log In", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .link
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        return button
    }()
    
    private let faceBookLoginButton: FBLoginButton = {
        let button = FBLoginButton()
        button.permissions = ["email, public_profile"]
        return button
    }()
    
    private let googleLogInButton = GIDSignInButton()
    
    private var loginObserver: NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loginObserver = NotificationCenter.default.addObserver(forName: .didLoginNotification, object: nil, queue: .main) { [weak self] _ in
            guard let strongSelf = self else {
                return
            }
            
            strongSelf.navigationController?.dismiss(animated: true, completion: nil)
        }
        
        GIDSignIn.sharedInstance()?.presentingViewController = self
        GIDSignIn.sharedInstance().signIn()
        
        title = "log in"
        view.backgroundColor = .white
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register",
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(didTapRegister))
        loginButton.addTarget(self,
                              action: #selector(didTapLogin),
                              for: .touchUpInside)
        
        faceBookLoginButton.delegate = self
        emailField.delegate = self
        passwordField.delegate = self
        
        view.addSubview(scrollView)
        scrollView.addSubview(LogoImageView)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(loginButton)
        scrollView.addSubview(faceBookLoginButton)
        scrollView.addSubview(googleLogInButton)
    }
    
    deinit {
        if let observer = loginObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        
        let size = scrollView.width/3
        LogoImageView.frame = CGRect(x: (view.width-size)/2,
                                     y: 50,
                                     width: size,
                                     height: size)
        
        emailField.frame = CGRect(x: 30,
                                  y: LogoImageView.bottom + 15,
                                  width: scrollView.width - 60,
                                  height: 52)
        passwordField.frame = CGRect(x: 30,
                                     y: emailField.bottom + 10,
                                     width: scrollView.width - 60,
                                     height: 52)
        loginButton.frame = CGRect(x: 30,
                                   y: passwordField.bottom + 20,
                                   width: scrollView.width - 60,
                                   height: 52)
        faceBookLoginButton.frame = CGRect(x: 30,
                                           y: loginButton.bottom + 10,
                                           width: scrollView.width - 60,
                                           height: 52)
        googleLogInButton.frame = CGRect(x: 30,
                                         y: faceBookLoginButton.bottom + 10,
                                         width: scrollView.width - 60,
                                         height: 52)
    }
    
    @objc private func didTapLogin() {
        
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        
        guard let email = emailField.text, let password = passwordField.text,
            !email.isEmpty, !password.isEmpty, password.count >= 6 else {
                alertUserLoginError()
                
                return
        }
        spinner.show(in: view)
        
        // Firebase Log In
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password) { [weak self] (authResult, error) in
            guard let strongSelf = self else {
                return
            }
            
            DispatchQueue.main.async {
                strongSelf.spinner.dismiss()
            }
            
            guard let result = authResult, error == nil else {
                print("Faild to log in user with email: \(email)")
                return
            }
            
            let user = result.user
            print("Logged In User: \(user)")
            strongSelf.navigationController?.dismiss(animated: true, completion: nil)
            
        }
    }
    
    private func alertUserLoginError() {
        let alert = UIAlertController(title: "Woops",
                                      message: "Please enter all information to log in.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss",
                                      style: .cancel,
                                      handler: nil))
        
        present(alert, animated: true)
    }
    
    @objc private func didTapRegister() {
        let vc = RegisterVC()
        vc.title = "Create Account"
        navigationController?.pushViewController(vc, animated: true)
    }
    
}

extension LoginVC: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if textField == emailField {
            passwordField.becomeFirstResponder()
        }
        else if textField == passwordField {
            didTapLogin()
        }
        return true
    }
}


extension LoginVC: LoginButtonDelegate {
    
    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        //
    }
    
    func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
        guard let token = result?.token?.tokenString else {
            
            return
        }
        
        let facebookRequest = FBSDKLoginKit.GraphRequest(graphPath: "me",
                                                         parameters: ["fields": "email, first_name, last_name , picture.type(large)"],
                                                         tokenString: token,
                                                         version: nil,
                                                         httpMethod: .get)
        facebookRequest.start { ( _, result, error) in
            guard let result = result as? [String: Any],
                error == nil else {
                    print("Failed to make facebook graph request")
                    return
            }
            
            guard let firstName = result["first_name"] as? String,
                let lastName = result["last_name"] as? String,
                let email = result["email"] as? String,
                let picture = result["picture"] as? [String: Any],
                let data = picture["data"] as? [String: Any],
                let pictureURL = data["url"] as? String else {
                    print("Failed to get email and name from fb result")
                    return
            }
            
            DatabaseManager.shared.userExists(with: email) { (exists) in
                if !exists {
                    let chatUser = ChatAppUser(firstName: firstName,
                                               lastName: lastName,
                                               emailAddress: email)
                    DatabaseManager.shared.insertUser(with: chatUser, completion: { success in
                        if success {
                            
                            guard let url = URL(string: pictureURL) else {
                                return
                            }
                            print("Download data from facebook image")
                            
                            URLSession.shared.dataTask(with: url) { (data, _, _) in
                                guard let data = data else {
                                    print("failed to get data from facebook")
                                    return
                                }
                                
                                print("got data from fb, uploading...")
                                
                                // upload image
                                let fileName = chatUser.profilePictureFileName
                                StorageManager.shared.uploadProfilePicture(with: data, fileName: fileName, completion: { result in
                                    switch result {
                                    case .success(let downloadURL):
                                        UserDefaults.standard.set(downloadURL, forKey: "profile_picture_url")
                                        print(downloadURL)
                                    case .failure(let error):
                                        print("Storage manager error: \(error)")
                                    }
                                })
                            }.resume()
                        }
                    })
                }
            }
            
            let credential = FacebookAuthProvider.credential(withAccessToken: token)
            FirebaseAuth.Auth.auth().signIn(with: credential) { [weak self] (authResult, error) in
                guard let strongSelf = self else {
                    return
                }
                
                guard authResult != nil , error == nil  else {
                    if let error = error {
                        print("Facebook credential login failed, MFA may be needed - \(error)")
                    }
                    return
                }
                
                print("Successfully logged user in")
                strongSelf.navigationController?.dismiss(animated: true, completion: nil)
            }
        }
    }
}
