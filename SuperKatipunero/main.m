//
//  main.m
//  SuperKoalio
//
//  Created by Jacob Gundersen on 6/4/12.
//  Copyright Interrobang Software LLC 2012. All rights reserved.
//

#import <UIKit/UIKit.h>

int main(int argc, char *argv[]) {
    
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    int retVal = UIApplicationMain(argc, argv, nil, @"AppController");
    [pool release];
    return retVal;
}
