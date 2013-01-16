//
// LXReorderableCollectionViewFlowLayout.h
//
// Created by Stan Chang Khin Boon on 1/10/12.
// Copyright (c) 2012 d--buzz. All rights reserved.
//
// Oldschool rewrite by Nat!  01/16/13
// This is MIT licensed
//

#import <UIKit/UIKit.h>


@interface LXReorderableCollectionViewFlowLayout : UICollectionViewFlowLayout < UIGestureRecognizerDelegate>
{
   UIEdgeInsets   triggerScrollingEdgeInsets_;
   CGFloat        scrollingSpeed_;
   
   // non-retained

   UILongPressGestureRecognizer   *longPressGestureRecognizer_;
   UIPanGestureRecognizer         *panGestureRecognizer_;

   // you probably should not mess with those when subclasssing
   //@private
   NSTimer        *scrollingTimer_;
   NSIndexPath    *selectedItemIndexPath_;
   
   UIView         *currentView_;
   CGPoint        currentViewCenter_;
   CGPoint        panTranslationInCollectionView_;
   
@protected
   BOOL           alwaysScroll_;
}


- (void) setUpGestureRecognizersOnCollectionView;

@end



@protocol LXReorderableCollectionViewDelegateFlowLayout<UICollectionViewDelegateFlowLayout>

- (void) collectionView:(UICollectionView *) collectionView
                 layout:(UICollectionViewLayout *) layout
        itemAtIndexPath:(NSIndexPath *) fromPath
    willMoveToIndexPath:(NSIndexPath *) destinationPath;

@optional

- (BOOL) collectionView:(UICollectionView *) collectionView
                 layout:(UICollectionViewLayout *) layout
        itemAtIndexPath:(NSIndexPath *) fromPath
  shouldMoveToIndexPath:(NSIndexPath *) destinationPath;

- (BOOL) collectionView:(UICollectionView *) collectionView
                 layout:(UICollectionViewLayout *) layout
   shouldBeginReorderingAtIndexPath:(NSIndexPath *) path;

- (void) collectionView:(UICollectionView *) collectionView
                 layout:(UICollectionViewLayout *) layout
   willBeginReorderingAtIndexPath:(NSIndexPath *) path;

- (void) collectionView:(UICollectionView *) collectionView
                 layout:(UICollectionViewLayout *) layout
   didBeginReorderingAtIndexPath:(NSIndexPath *) path;

- (void) collectionView:(UICollectionView *) collectionView
                 layout:(UICollectionViewLayout *) layout
   willEndReorderingAtIndexPath:(NSIndexPath *) path;

- (void) collectionView:(UICollectionView *) collectionView
                 layout:(UICollectionViewLayout *) layout
   didEndReorderingAtIndexPath:(NSIndexPath *) path;

@end

