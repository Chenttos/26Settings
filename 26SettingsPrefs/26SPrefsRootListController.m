#import <Preferences/PSListController.h>
#import <spawn.h>

@interface MLYPrefsRootListController : PSListController
@end

@implementation MLYPrefsRootListController

- (NSArray *)specifiers {
    if (_specifiers) return _specifiers;
    _specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
    return _specifiers;
}

- (void)respring {
    pid_t pid;
    const char *args[] = { "killall", "-9", "SpringBoard", NULL };
    posix_spawn(&pid, "/usr/bin/killall", NULL, NULL, (char *const *)args, NULL);
    waitpid(pid, NULL, 0);
}

@end
