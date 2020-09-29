//
//  PhotoViewerVC.swift
//  Chat_App
//
//  Created by sa3doola on 9/12/20.
//  Copyright © 2020 saad sherif. All rights reserved.
//

import UIKit
import SDWebImage

final class PhotoViewerVC: UIViewController {
    
    private let url: URL
    
    init(with url: URL) {
        self.url = url
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let imageView: UIImageView = {
       let image = UIImageView()
        image.contentMode = .scaleAspectFit
        return image
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Photo"
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = .black
        view.addSubview(imageView)
        imageView.sd_setImage(with: url, completed: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        imageView.frame = view.bounds
    }
    
}
