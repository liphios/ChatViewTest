//
//  AppDelegate.h
//  ChatViewTest
//
//  Created by caishangcai on 2017/11/27.
//  Copyright © 2017年 caishangcai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong) NSPersistentContainer *persistentContainer;

- (void)saveContext;

@property (nonatomic,strong)NSMutableArray *userList;



@end

