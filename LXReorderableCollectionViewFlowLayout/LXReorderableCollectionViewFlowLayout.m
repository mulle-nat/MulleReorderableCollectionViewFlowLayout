//
// LXReorderableCollectionViewFlowLayout.m
//
// Created by Stan Chang Khin Boon on 1/10/12.
// Copyright (c) 2012 d--buzz. All rights reserved.
//

#import "LXReorderableCollectionViewFlowLayout.h"
#import <QuartzCore/QuartzCore.h>

#define LX_FRAMES_PER_SECOND 60.0


#ifndef CGGEOMETRY_LXSUPPORT_H_
CG_INLINE CGPoint LXS_CGPointAdd(CGPoint thePoint1, CGPoint thePoint2)
{
   return(CGPointMake(thePoint1.x + thePoint2.x, thePoint1.y + thePoint2.y));
}


#endif

typedef NS_ENUM (NSInteger, LXDirection) {
   LXUp = 1,
   LXDown,
   LXLeft,
   LXRight
};

static NSString *LXScrollingDirectionKey = @"LXScrollingDirection";



@interface LXReorderableCollectionViewFlowLayout ()

- (void) applyLayoutAttributes:(UICollectionViewLayoutAttributes *) attributes;

@end


@interface UICollectionViewLayoutAttributes ( LXReorderableCollectionViewFlowLayout)

- (void) applyToLayoutIfNeeded:(LXReorderableCollectionViewFlowLayout *) layout;

@end


@implementation UICollectionViewLayoutAttributes ( LXReorderableCollectionViewFlowLayout)

- (void) applyToLayoutIfNeeded:(LXReorderableCollectionViewFlowLayout *) layout
{
   if( [self representedElementCategory] == UICollectionElementCategoryCell)
        [layout applyLayoutAttributes:self];
}
        
@end

        
@implementation LXReorderableCollectionViewFlowLayout

- (void) setUpGestureRecognizersOnCollectionView
{
   UILongPressGestureRecognizer   *longer;
   UIPanGestureRecognizer         *panner;
   UICollectionView               *collectionView;
   
   collectionView = [self collectionView];
   
   longer = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                          action:@selector( handleLongPressGesture:)];

   [longer setDelegate:self];
   [collectionView addGestureRecognizer:longer];
   [self setLongPressGestureRecognizer:longer];

   // Links the default long press gesture recognizer to the custom long press
   // gesture recognizer we are creating now by enforcing failure dependency
   // so that they doesn't clash.
   for( UIGestureRecognizer *recognizer in [collectionView gestureRecognizers])
   {
      if( [recognizer isKindOfClass:[UILongPressGestureRecognizer class]])
         [recognizer requireGestureRecognizerToFail:longer];
   }
   

   panner = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                    action:@selector( handlePanGesture:)];
   [panner setDelegate:self];
   [collectionView addGestureRecognizer:panner];
   
   [self setPanGestureRecognizer:panner];

   [self setTriggerScrollingEdgeInsets:UIEdgeInsetsMake( 50.0f, 50.0f, 50.0f, 50.0f)];
   [self setScrollingSpeed:300.0f];

   [self invalidateAutoScroll];

   [self setAlwaysScroll:YES];
}


- (void) awakeFromNib
{
   [self setUpGestureRecognizersOnCollectionView];
}


#pragma mark - Custom methods

- (void) applyLayoutAttributes:(UICollectionViewLayoutAttributes *) attributes
{
   if( [[attributes indexPath] isEqual:[self selectedItemIndexPath]])
      [attributes setHidden:YES];
}


- (void) invalidateLayoutIfNecessary
{
   NSIndexPath        *selectedPath;
   BOOL               shouldMove;
   NSIndexPath        *previousPath;
   UICollectionView   *collectionView;
   id<LXReorderableCollectionViewDelegateFlowLayout>   delegate;
   
   collectionView = [self collectionView];
   selectedPath   = [collectionView indexPathForItemAtPoint:self.currentView.center];
   previousPath   = [self selectedItemIndexPath];
   
   if( ! selectedPath || [selectedPath isEqual:previousPath])
      return;
   
   [self setSelectedItemIndexPath:selectedPath];
   
   delegate = (id <LXReorderableCollectionViewDelegateFlowLayout> ) [collectionView delegate];
   if( [delegate conformsToProtocol:@protocol( LXReorderableCollectionViewDelegateFlowLayout)])
   {
      // Check with the delegate to see if this move is even allowed.
      if( [delegate respondsToSelector:@selector( collectionView:layout:itemAtIndexPath:shouldMoveToIndexPath: )])
      {
         shouldMove = [delegate collectionView:collectionView
                                        layout:self
                               itemAtIndexPath:previousPath
                         shouldMoveToIndexPath:selectedPath];
         
         if( ! shouldMove)
            return;
      }
      
      // Proceed with the move
      [delegate collectionView:collectionView
                        layout:self
               itemAtIndexPath:previousPath
           willMoveToIndexPath:selectedPath];
   }
   
   [collectionView performBatchUpdates:^{
      // [self.collectionView moveItemAtIndexPath:previousPath toIndexPath:selectedPath];
      [collectionView deleteItemsAtIndexPaths:@[previousPath]];
      [collectionView insertItemsAtIndexPaths:@[selectedPath]];
   } completion:^(BOOL finished) {
   }];
}


#pragma mark - Target/Action methods

- (void) handleScroll:(NSTimer *) timer
{
   LXDirection   dir;
   CGFloat   theDistance;
   CGPoint   theContentOffset;
   CGPoint   translation;
   CGRect    bounds;
   CGSize    contentSize;
   CGFloat   theMinX;
   CGFloat   theMaxX;
   CGFloat   theMinY;
   CGFloat   theMaxY;
   
   dir = (LXDirection) [[timer userInfo][ LXScrollingDirectionKey] integerValue];

   theDistance      = self.scrollingSpeed / LX_FRAMES_PER_SECOND;
   theContentOffset = self.collectionView.contentOffset;
   bounds = self.collectionView.bounds;
   contentSize   = self.collectionView.contentSize;
   
   switch( dir)
   {
   case LXUp:
      theDistance = -theDistance;
      theMinY     = 0.0f;

      if( (theContentOffset.y + theDistance) <= theMinY)
         theDistance = -theContentOffset.y;

      translation = CGPointMake( 0.0f, theDistance);
      break;

   case LXDown:
      theMaxY = MAX( contentSize.height, CGRectGetHeight( bounds)) - CGRectGetHeight( bounds);

      if( (theContentOffset.y + theDistance) >= theMaxY)
         theDistance = theMaxY - theContentOffset.y;
         
      translation = CGPointMake( 0.0f, theDistance);
      break;

   case LXLeft:
      theDistance = -theDistance;
      theMinX     = 0.0f;

      if( (theContentOffset.x + theDistance) <= theMinX)
         theDistance = -theContentOffset.x;
      translation = CGPointMake( theDistance, 0.0f);
      break;

   case LXRight:
      theMaxX = MAX( contentSize.width, CGRectGetWidth( bounds)) - CGRectGetWidth( bounds);

      if((theContentOffset.x + theDistance) >= theMaxX)
         theDistance = theMaxX - theContentOffset.x;
      translation = CGPointMake( theDistance, 0.0f);
      break;

   default:
         abort();
   }
   
   self.collectionView.contentOffset = LXS_CGPointAdd( theContentOffset, translation);
   self.currentViewCenter            = LXS_CGPointAdd( self.currentViewCenter, translation);
   self.currentView.center           = LXS_CGPointAdd( self.currentViewCenter, self.panTranslationInCollectionView);
}


- (void) handleLongPressGesture:(UILongPressGestureRecognizer *) theLongPressGestureRecognizer
{
   switch( theLongPressGestureRecognizer.state)
   {
   case UIGestureRecognizerStateBegan:
   {
      CGPoint       theLocationInCollectionView = [theLongPressGestureRecognizer locationInView:self.collectionView];
      NSIndexPath   *selectedPath =
         [self.collectionView indexPathForItemAtPoint:theLocationInCollectionView];

      if( [self.collectionView.delegate conformsToProtocol:@protocol( LXReorderableCollectionViewDelegateFlowLayout )])
      {
         id<LXReorderableCollectionViewDelegateFlowLayout>   delegate =
            (id<LXReorderableCollectionViewDelegateFlowLayout> )self.collectionView.delegate;

         if( [delegate respondsToSelector:@selector( collectionView:layout:shouldBeginReorderingAtIndexPath: )])
         {
            BOOL   shouldStartReorder =
               [delegate collectionView:self.collectionView layout:self shouldBeginReorderingAtIndexPath:
                selectedPath];

            if( ! shouldStartReorder)
               return;
         }

         if( [delegate respondsToSelector:@selector( collectionView:layout:willBeginReorderingAtIndexPath: )])
            [delegate collectionView:self.collectionView layout:self willBeginReorderingAtIndexPath:
             selectedPath];
      }

      UICollectionViewCell   *theCollectionViewCell =
         [self.collectionView cellForItemAtIndexPath:selectedPath];

      theCollectionViewCell.highlighted = YES;
      UIGraphicsBeginImageContextWithOptions(theCollectionViewCell.bounds.size, theCollectionViewCell.opaque, 0.0f);
      [theCollectionViewCell.layer renderInContext:UIGraphicsGetCurrentContext()];
      UIImage   *theHighlightedImage = UIGraphicsGetImageFromCurrentImageContext();
      UIGraphicsEndImageContext();

      theCollectionViewCell.highlighted = NO;
      UIGraphicsBeginImageContextWithOptions(theCollectionViewCell.bounds.size, theCollectionViewCell.opaque, 0.0f);
      [theCollectionViewCell.layer renderInContext:UIGraphicsGetCurrentContext()];
      UIImage   *theImage = UIGraphicsGetImageFromCurrentImageContext();
      UIGraphicsEndImageContext();

      UIImageView   *theImageView = [[UIImageView alloc] initWithImage:theImage];
      theImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;    // Not using constraints, lets auto resizing mask be translated automatically...

      UIImageView   *theHighlightedImageView = [[UIImageView alloc] initWithImage:theHighlightedImage];
      theHighlightedImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;    // Not using constraints, lets auto resizing mask be translated automatically...

      UIView   *theView =
         [[UIView alloc] initWithFrame:CGRectMake(CGRectGetMinX(theCollectionViewCell.frame),
                                                  CGRectGetMinY(theCollectionViewCell.frame),
                                                  CGRectGetWidth(theImageView.frame),
                                                  CGRectGetHeight(theImageView.frame))];

      [theView addSubview:theImageView];
      [theView addSubview:theHighlightedImageView];

      [self.collectionView addSubview:theView];

      self.selectedItemIndexPath = selectedPath;
      self.currentView           = theView;
      self.currentViewCenter     = theView.center;

      theImageView.alpha            = 0.0f;
      theHighlightedImageView.alpha = 1.0f;

      [UIView
          animateWithDuration:0.3
                   animations:^{
          theView.transform = CGAffineTransformMakeScale(1.1f, 1.1f);
          theImageView.alpha = 1.0f;
          theHighlightedImageView.alpha = 0.0f;
       }


                   completion:^(BOOL finished) {
          [theHighlightedImageView removeFromSuperview];

          if( [self.collectionView.delegate conformsToProtocol:@protocol( LXReorderableCollectionViewDelegateFlowLayout )
              ])
          {
             id<LXReorderableCollectionViewDelegateFlowLayout> delegate =
                (id<LXReorderableCollectionViewDelegateFlowLayout> )self.collectionView.delegate;

             if( [delegate respondsToSelector:@selector( collectionView:layout:didBeginReorderingAtIndexPath: )])
                [delegate collectionView:self.collectionView layout:self didBeginReorderingAtIndexPath:
                 selectedPath];
          }
       }];

      [self invalidateLayout];
   } break;

   case UIGestureRecognizerStateEnded:
   {
      NSIndexPath   *selectedPath = self.selectedItemIndexPath;

      if( [self.collectionView.delegate conformsToProtocol:@protocol( LXReorderableCollectionViewDelegateFlowLayout )])
      {
         id<LXReorderableCollectionViewDelegateFlowLayout>   delegate =
            (id<LXReorderableCollectionViewDelegateFlowLayout> )self.collectionView.delegate;

         if( [delegate respondsToSelector:@selector( collectionView:layout:willEndReorderingAtIndexPath: )])
            [delegate collectionView:self.collectionView layout:self willEndReorderingAtIndexPath:
             selectedPath];
      }

      self.selectedItemIndexPath = nil;
      self.currentViewCenter     = CGPointZero;

      if( selectedPath)
      {
         UICollectionViewLayoutAttributes   *theLayoutAttributes =
            [self layoutAttributesForItemAtIndexPath:selectedPath];

         __weak LXReorderableCollectionViewFlowLayout   *theWeakSelf = self;
         [UIView
             animateWithDuration:0.3f
                      animations:^{
             __strong LXReorderableCollectionViewFlowLayout *theStrongSelf = theWeakSelf;

             theStrongSelf.currentView.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
             theStrongSelf.currentView.center = theLayoutAttributes.center;
          }


                      completion:^(BOOL finished) {
             __strong LXReorderableCollectionViewFlowLayout *theStrongSelf = theWeakSelf;

             [theStrongSelf.currentView removeFromSuperview];
             [theStrongSelf invalidateLayout];

             if( [self.collectionView.delegate conformsToProtocol:@protocol(
                     LXReorderableCollectionViewDelegateFlowLayout )])
             {
                id<LXReorderableCollectionViewDelegateFlowLayout> delegate =
                   (id<LXReorderableCollectionViewDelegateFlowLayout> )self.collectionView.delegate;

                if( [delegate respondsToSelector:@selector( collectionView:layout:didEndReorderingAtIndexPath: )])
                   [delegate collectionView:self.collectionView layout:self didEndReorderingAtIndexPath:
                    selectedPath];
             }
          }];
      }
   } break;

   default:
      break;
   }
}


- (void) invalidateAutoScroll
{
   [[self scrollingTimer] invalidate];
   [self setScrollingTimer:nil];
}


- (void) setupAutoScrollInDirection:(NSInteger) dir
{
   NSTimer    *timer;
   NSInteger  oldDir;
   
   timer = [self scrollingTimer];
   
   if( [timer isValid])
   {
      oldDir = [[[timer userInfo] objectForKey:LXScrollingDirectionKey] integerValue];
      if( dir == oldDir)
         return;
   }
   
   [self invalidateAutoScroll];
   
   timer = [NSTimer scheduledTimerWithTimeInterval:1.0 / LX_FRAMES_PER_SECOND
                                            target:self
                                          selector:@selector( handleScroll:)
                                          userInfo:@{ LXScrollingDirectionKey : @( dir ) }
                                           repeats:YES];
   
   [self setScrollingTimer:timer];
}


- (void) handlePanGesture:(UIPanGestureRecognizer *) recognizer
{
   CGPoint        translation;
   CGPoint        location;
   UIEdgeInsets   insets;
   UICollectionView   *collectionView;
   CGRect          bounds;
   
   switch( [recognizer state])
   {
      case UIGestureRecognizerStateBegan   :
      case UIGestureRecognizerStateChanged :
      {
         translation = [recognizer translationInView:self.collectionView];
         location = LXS_CGPointAdd(self.currentViewCenter, self.panTranslationInCollectionView);

         self.panTranslationInCollectionView = translation;
         self.currentView.center = location;
         
         [self invalidateLayoutIfNecessary];
   
         insets         = [self triggerScrollingEdgeInsets];
         collectionView = [self collectionView];
         bounds         = [collectionView bounds];
         
         switch( [self scrollDirection])
         {
            case UICollectionViewScrollDirectionVertical :
               if( location.y < (CGRectGetMinY( bounds) + insets.top))
                  [self setupAutoScrollInDirection:LXUp];
               else
                  if( location.y > (CGRectGetMaxY( bounds) - insets.bottom))
                     [self setupAutoScrollInDirection:LXDown];
                  else
                     [self invalidateAutoScroll];
               
               break;
               
            case UICollectionViewScrollDirectionHorizontal :
               if( location.x < (CGRectGetMinX( bounds) + insets.left))
                  [self setupAutoScrollInDirection:LXLeft];
               else
                  if( location.x > (CGRectGetMaxX( bounds) - insets.right))
                     [self setupAutoScrollInDirection:LXRight];
                  else
                     [self invalidateAutoScroll];
               
               break;
         }
      }
         break;
         
      case UIGestureRecognizerStateEnded:
         [self invalidateAutoScroll];
         break;
   }
}


#pragma mark - UICollectionViewFlowLayoutDelegate methods


- (NSArray *) layoutAttributesForElementsInRect:(CGRect) theRect
{
   NSArray   *array;

   array = [super layoutAttributesForElementsInRect:theRect];
   
   [array makeObjectsPerformSelector:@selector( applyToLayoutIfNeeded:)
                                    withObject:self];
   return( array);
}


- (UICollectionViewLayoutAttributes *) layoutAttributesForItemAtIndexPath:(NSIndexPath *) path
{
   UICollectionViewLayoutAttributes   *attributes;
   
   attributes = [super layoutAttributesForItemAtIndexPath:path];
   [attributes applyToLayoutIfNeeded:self];

   return( attributes);
}


- (CGSize) collectionViewContentSize
{
   CGSize   size;
   CGRect   bounds;
   
   size = [super collectionViewContentSize];
   
   if( ! [self alwaysScroll])
      return( size);
   
   bounds = [[self collectionView] bounds];
   switch( [self scrollDirection])
   {
   case UICollectionViewScrollDirectionVertical :
      if( size.height <= CGRectGetHeight( bounds))
         size.height = CGRectGetHeight(bounds) + 1.0f;
      break;
      
   case UICollectionViewScrollDirectionHorizontal :
      if( size.width <= CGRectGetWidth( bounds))
         size.width = CGRectGetWidth( bounds) + 1.0f;
      break;
   }
   
   return( size);
}


#pragma mark - UIGestureRecognizerDelegate methods

- (BOOL) gestureRecognizerShouldBegin:(UIGestureRecognizer *) recognizer
{
   if( [[self panGestureRecognizer] isEqual:recognizer])
      return( [self selectedItemIndexPath] != nil);

   return( YES);
}


- (BOOL) gestureRecognizer:(UIGestureRecognizer *) recognizer
   shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *) other
{
   UIGestureRecognizer   *panner;
   UIGestureRecognizer   *longer;
   
   panner = [self panGestureRecognizer];
   longer = [self longPressGestureRecognizer];
   
   if( [longer isEqual:recognizer])
      return( [panner isEqual:other]);
   
   if( [panner isEqual:recognizer])
      return( [longer isEqual:other]);
   
   return( NO);
}

@end

