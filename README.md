MulleReorderableCollectionViewFlowLayout
=====================================

Extends `UICollectionViewFlowLayout` to support reordering of cells. Similar to long press and pan on books in iBook.

Beware!! 

I turned a nice decent iOS project, into (almost) old man's ObjC-1.0 code, that doesn't need ARC. 
The beautiful long variable names are gone, and the nice ObjC-2.0 magic has been reduced to minimum.

It sucks now, so don't use it :) You probably want the original.

Har har

Nat!


Features
========

The goal of MulleReorderableCollectionViewFlowLayout is to provides capability for reordering of cell, similar to iBook.

 - Long press on cell invoke reordering capability.
 - When reordering capability is invoked, fade the selected cell from highlighted to normal state.
 - Drag around the selected cell to move it to the desired location, other cells adjust accordingly. Callback in the form of delegate methods are invoked.
 - Drag selected cell to the edges, depending on scroll direction, autoscroll in the desired direction.
 - Release to stop reordering.

Getting Started
===============

<img src="https://raw.github.com/lxcid/LXReorderableCollectionViewFlowLayout/master/Content/Screenshots/screenshot1.png" alt="Screenshot" title="Screenshot" style="display:block; margin: 10px auto 30px auto; width: 300px; height: 400px;" class="center">

 1. Drag the `MulleReorderableCollectionViewFlowLayout` folder into your project.
 2. Initialize/Setup your collection view to use `MulleReorderableCollectionViewFlowLayout`.
 3. If you setup your collection view programmatically, make sure you call `[MulleReorderableCollectionViewFlowLayout setUpGestureRecognizersOnCollectionView]` instance method after the collection view is setup.

        [theReorderableCollectionViewFlowLayout setUpGestureRecognizersOnCollectionView];

 4. The collection view controller that is to support reordering capability must conforms to `MulleReorderableCollectionViewDelegateFlowLayout` protocol. For example,

        - (void)collectionView:(UICollectionView *)theCollectionView layout:(UICollectionViewLayout *)theLayout itemAtIndexPath:(NSIndexPath *)theFromIndexPath willMoveToIndexPath:(NSIndexPath *)theToIndexPath {
            id theFromItem = [self.deck objectAtIndex:theFromIndexPath.item];
            [self.deck removeObjectAtIndex:theFromIndexPath.item];
            [self.deck insertObject:theFromItem atIndex:theToIndexPath.item];
        }

 5. Setup your collection view accordingly to your need, run and see it in action! :D

Limitations
===========

Collection view come with a default long press gesture recognizer and because we defined our own custom long press gesture recognizer, we created a link between them that requires the custom one to fails before the default one can began.

In short, we took over the responsibility of long press gesture with the custom one from the default one. You can disable the custom long press gesture recognizer with the following code snippet, `self.longPressGestureRecognizer.enabled = YES`, which enabled the default behavior again.

Requirements
============

 - iOS 6
 - Xcode 4.5 and above

Credits
=======

MulleReorderableCollectionViewFlowLayout is a fork and a rewrite of LXReorderableCollectionViewFlowLayout by Nat!.

LXReorderableCollectionViewFlowLayout was created by [Stan Chang Khin Boon](https://github.com/Mullecid) as part of a project under [buUuk](http://www.buuuk.com/).

Many thanks to __MaximilianL__ in the [Apple Developer Forums for sharing his implementation](https://devforums.apple.com/message/682764) which lead him to this project.

The playing cards in the demo are downloaded from [http://www.jfitz.com/cards/](http://www.jfitz.com/cards/).

README.md structure is heavily referenced from [AFNetworking](https://github.com/AFNetworking/AFNetworking).

### Creators

[Nat!] (http://github.com/mulle-nat)  
[Stan Chang Khin Boon](http://github.com/lxcid)  

License
=======

MulleReorderableCollectionViewFlowLayout 
========================================
is available under the MIT license.

