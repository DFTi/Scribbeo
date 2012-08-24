//
//  MyPlayerLayerView.m
//  VideoTree
//
//  Created by Steve Kochan on 9/10/10.
//  Copyright © 2010-2011 by Digital Film Tree. All rights reserved.
//

#import "MyPlayerLayerView.h"

#import <AVFoundation/AVFoundation.h>

@implementation MyPlayerLayerView


+ (Class)layerClass
{
	return [AVPlayerLayer class];
}

- (AVPlayerLayer *)playerLayer
{
	return (AVPlayerLayer *)self.layer;
}

- (void)setPlayerLayer: (AVPlayer *) player
{
	[(AVPlayerLayer *)[self layer] setPlayer: player];
}

#if 0
- (AVPlayer*)player {
    return [(AVPlayerLayer *)[self layer] player];
}

- (void)setPlayer:(AVPlayer *)player {
    [(AVPlayerLayer *)[self layer] setPlayer:player];
}
#endif 

@end

