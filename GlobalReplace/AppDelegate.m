//
//  AppDelegate.m
//  GlobalReplace
//
//  Created by ZhangAo on 14-7-13.
//  Copyright (c) 2014年 ZA. All rights reserved.
//

#import "AppDelegate.h"
#import "RegExCategories.h"
#import "FileMatchResult.h"

@interface AppDelegate () <NSUserNotificationCenterDelegate,NSOutlineViewDataSource,NSOutlineViewDelegate>

@property (nonatomic, weak) IBOutlet NSTextField *filesCountLabel;
@property (nonatomic, weak) IBOutlet NSButton *replaceButton;
@property (nonatomic, weak) IBOutlet NSButton *searchButton;

@property (nonatomic, copy) NSArray *files;
@property (nonatomic, copy) NSArray *fileMatchsList;

@property (nonatomic, assign) IBOutlet NSTextView *sourceView;
@property (nonatomic, assign) IBOutlet NSTextView *destView;

@property (nonatomic, weak) IBOutlet NSPanel *sheet;
@property (nonatomic, weak) IBOutlet NSOutlineView *outlineView;
@property (nonatomic, assign) IBOutlet NSTextView *matchDetailView;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self.sourceView setRichText:NO];
    [self.destView setRichText:NO];
}

-(NSPanel *)sheet{
    if (_sheet == nil) {
        [[NSBundle mainBundle] loadNibNamed:@"SearchResultPanel" owner:self topLevelObjects:nil];
    }
    return _sheet;
}

-(IBAction)showChooseDirectory:(id)sender{
    NSOpenPanel *openPanel = [NSOpenPanel new];
    openPanel.canChooseDirectories = YES;
    openPanel.canChooseFiles = NO;
    openPanel.allowsMultipleSelection = NO;
    
    if (openPanel.runModal == NSOKButton) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSError *error;
        self.files = [fileManager contentsOfDirectoryAtURL:openPanel.URL
                                includingPropertiesForKeys:nil
                                                   options:NSDirectoryEnumerationSkipsHiddenFiles
                                                     error:&error];
        if (error) {
            [self showTipsTitle:@"错误" content:error.localizedDescription];
            [self.replaceButton setEnabled:NO];
        } else {
            self.filesCountLabel.stringValue = [NSString stringWithFormat:@"共有%ld个文件",self.files.count];
            [self.replaceButton setEnabled:YES];
        }
        [self.searchButton setEnabled:self.replaceButton.isEnabled];
    }
}

-(void)showTipsTitle:(NSString *)title content:(NSString *)content{
    NSUserNotification *noti = [NSUserNotification new];
    noti.title = title;
    noti.informativeText = content;
    NSUserNotificationCenter *uc = [NSUserNotificationCenter defaultUserNotificationCenter];
    uc.delegate = self;
    [uc deliverNotification:noti];
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification
{
    return YES;
}

-(IBAction)search:(NSButton *)searchButton{
    if (self.sourceView.string.length == 0) {
        [self showTipsTitle:@"提示" content:@"请输入需要查找的文本"];
        return;
    }
    NSError *error;
    
    int i = 0;
    NSMutableArray *fileMatchsList = [NSMutableArray array];
    for (NSURL *fileUrl in self.files) {
        NSString *fileContent = [NSString stringWithContentsOfURL:fileUrl
                                                         encoding:NSUTF8StringEncoding
                                                            error:&error];
        NSRegularExpression *pattern = [NSRegularExpression rx:self.sourceView.string options:0];
        
        if (error) {
            [self showTipsTitle:@"错误" content:error.localizedDescription];
        } else {
            NSArray *matchs = [fileContent matches:pattern];
            if (matchs.count > 0) {
                FileMatchResult *matchResult = [FileMatchResult new];
                matchResult.matchs = matchs;
                i += matchResult.matchs.count;
                matchResult.fileName = fileUrl.lastPathComponent;
                [fileMatchsList addObject:matchResult];                
            }
        }
    }

    [self showSheet];
    
    self.fileMatchsList = fileMatchsList;
    
    [self showTipsTitle:@"搜索结果" content:[NSString stringWithFormat:@"共找到%d条匹配结果",i]];
    [self.outlineView reloadData];
}

-(IBAction)searchAndReplace:(id)sender{
    if (self.sourceView.string.length == 0) {
        [self showTipsTitle:@"提示" content:@"请输入需要查找的文本"];
        return;
    }
    NSError *error;
    
    int i = 0;
    for (NSURL *fileUrl in self.files) {
        NSString *fileContent = [NSString stringWithContentsOfURL:fileUrl
                                                         encoding:NSUTF8StringEncoding
                                                            error:&error];
        NSRegularExpression *pattern = [NSRegularExpression rx:self.sourceView.string options:0];
        
        if (error) {
            [self showTipsTitle:@"错误" content:error.localizedDescription];
        } else {
            NSArray *matchs = [fileContent matches:pattern];
            if (matchs.count > 0) {
                NSString *replacedContent = [fileContent replace:pattern with:self.destView.string];
                NSError *error;
                [replacedContent writeToURL:fileUrl atomically:YES encoding:NSUTF8StringEncoding error:&error];
                if (error) {
                    [self showTipsTitle:error.localizedDescription content:@"错误"];
                } else {
                    i += matchs.count;
                }
            }
        }
    }
    
    [self showTipsTitle:@"替换完成" content:[NSString stringWithFormat:@"共替换%d个匹配对象",i]];
}

-(void)showSheet{
    [[NSApplication sharedApplication] beginSheet:self.sheet
                                   modalForWindow:[NSApp mainWindow]
                                    modalDelegate:self
                                   didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
                                      contextInfo:(__bridge void *)(self)];
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo{
    [sheet orderOut:self];
}

-(IBAction)cancelSheet:(id)sender{
    [[NSApplication sharedApplication] endSheet:self.sheet returnCode:NSCancelButton];
}

#pragma mark - NSOutlineViewDataSource,NSOutlineViewDelegate methods
- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item{
    return self.fileMatchsList.count;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item{
    FileMatchResult *matchResult = self.fileMatchsList[index];
    return matchResult.fileName;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item{
    return NO;
}

-(NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item{
    NSTableCellView *cell = [outlineView makeViewWithIdentifier:@"DataCell" owner:self];
    cell.textField.stringValue = item;
    return cell;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item{
    self.matchDetailView.string = @"";
    NSUInteger row = [outlineView rowForItem:item];
    FileMatchResult *matchResult = self.fileMatchsList[row];
    
    int i = 1;
    for (NSString *match in matchResult.matchs) {
        NSMutableAttributedString *attriStr = [[NSMutableAttributedString alloc] initWithString:[match stringByAppendingString:@"\n"]
                                                                                     attributes:@{NSForegroundColorAttributeName:
                                                                                                      (i % 2 == 0 ? [NSColor blackColor] : [NSColor blueColor])}];
        [self.matchDetailView.textStorage appendAttributedString:attriStr];
        i++;
    }
    [self.matchDetailView scrollToBeginningOfDocument:nil];
    return YES;
}

@end
