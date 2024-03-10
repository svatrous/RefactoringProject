//
//  ViewController.swift
//  CodingSession
//
//  Created by Pavel Ilin on 01.11.2023.
//

import Accelerate
import Combine
import SnapKit
import Photos
import UIKit

final class ViewController: UIViewController {
    
    private lazy var collectionView: UICollectionView = .init(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    private lazy var loadingView: UIActivityIndicatorView = .init()
    
    private var targetSize: CGSize = .init(width: UIScreen.main.bounds.width / 3, height: UIScreen.main.bounds.width / 3)
    private var disposables: Set<AnyCancellable> = .init()
    private var viewModel: PhotoViewModel = .init()
    
    private lazy var dateFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.zeroFormattingBehavior = [.pad]
        formatter.unitsStyle = .positional
        return formatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
    }
    
    private func setupUI() {
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        view.addSubview(loadingView)
        loadingView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        collectionView.register(ViewControllerCell.self)
        collectionView.delegate = self
        collectionView.dataSource = self
    }
    
    private func bindViewModel() {
        
        viewModel.hasAccess
            .receive(on: DispatchQueue.main)
            .sink { [weak self] access in
                guard let self, access else { return }
                viewModel.loadData()
            }
            .store(in: &disposables)
        
        viewModel.items
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.collectionView.reloadData()
            }
            .store(in: &disposables)
        
        viewModel.loading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                if isLoading {
                    self?.loadingView.startAnimating()
                } else {
                    self?.loadingView.stopAnimating()
                }
            }
            .store(in: &disposables)
        
        viewModel.error
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.handleError(error)
            }
            .store(in: &disposables)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        viewModel.grantAccess()
    }
    
    private func handleError(_ error: Error) {
        let alert = UIAlertController(title: String(localized: "Failed to load data", comment: "Failed to load data"),
                                      message: error.localizedDescription,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: String(localized:"OK", comment: "OK"), style: .cancel))
        present(alert, animated: true)
    }
}

extension ViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(with: ViewControllerCell.self, for: indexPath)
        
        let asset = viewModel.items.value[indexPath.row]
        
        cell.thumbImageView.image = nil
        
        viewModel.requestImage(asset, size: targetSize) { image in
            cell.thumbImageView.image = image
        }
        
        cell.durationLabel.text = dateFormatter.string(from: asset.duration)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.items.value.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        targetSize
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        .zero
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        0
    }
}
