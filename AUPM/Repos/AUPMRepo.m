#import "AUPMRepo.h"

@implementation AUPMRepo

- (id)initWithRepoInformation:(NSDictionary *)information {

    [self setIcon:information[@"Icon"]];
    [self setRepoName:information[@"Origin"]];
    [self setRepoBaseFileName:information[@"baseFileName"]];
    [self setDescription:information[@"Description"]];
    [self setRepoURL:information[@"URL"]];

    return self;
}

- (void)setIcon:(NSData *)ico {
    if (ico != NULL) {
        icon = ico;
    }
}

- (void)setRepoName:(NSString *)name {
    if (name != NULL) {
        repoName = name;
    }
}

- (void)setRepoBaseFileName:(NSString *)filename {
    if (filename != NULL) {
        repoBaseFileName = filename;
    }
}

- (void)setDescription:(NSString *)desc {
    if (desc != NULL) {
        description = desc;
    }
}

- (void)setRepoURL:(NSString *)url {
    if (url != NULL) {
        repoURL = url;
    }
}

- (NSData *)icon {
    return icon;
}

- (NSString *)repoName {
    return repoName;
}

- (NSString *)repoBaseFileName {
    return repoBaseFileName;
}

- (NSString *)description {
    return description;
}
- (NSString *)repoURL {
    return repoURL;
}
@end
