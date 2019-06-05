//
//  ViewController.swift
//  LiveView Expample
//
//  Created by Pavel Puzyrev on 23/12/2018.
//  Copyright © 2018 Pavel Puzyrev. All rights reserved.
//

import UIKit
import LiveView

class ViewController: UIViewController {

    @IBOutlet weak var liveView: LiveView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("viewDidLoad")

        let liveView = self.liveView as! LiveViewInterface

        let previewUrl = Bundle.main.url(forResource: "HG_low", withExtension: "JPG")!
        liveView.show(placeholderImage: previewUrl, animated: false, completionHandler: nil)

        print(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask))
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("viewDidAppear")

        let imageUrl = Bundle.main.url(forResource: "HG", withExtension: "JPG")!
        let movieUrl = Bundle.main.url(forResource: "HG", withExtension: "MOV")!

//        liveView.show(imageResource: imageUrl, movieResource: movieUrl, animated: true, completionHandler: nil)
        liveView.show(image: movieUrl, animated: true, completionHandler: { error in
            if let error = error {
                print(error.localizedDescription)
            }
//            self.liveView.saveToLibrary(completionHandler: { error in
//                print(error)
//            })
        })
    }
}

