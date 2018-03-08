#import "AUPMRepo.h"

@implementation AUPMRepo

- (id)initWithRepoInformation:(NSDictionary *)information {

    [self setIcon:information[@"Icon"]];
    [self setRepoName:information[@"Origin"]];
    [self setRepoURL:information[@"URL"]];
    [self setDescription:information[@"Description"]];

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

- (void)setRepoURL:(NSString *)url {
    if (url != NULL) {
        repoURL = url;
    }
}

- (void)setDescription:(NSString *)desc {
    if (desc != NULL) {
        description = desc;
    }
}

- (NSData *)icon {
    return icon;
}

- (NSString *)repoName {
    return repoName;
}

- (NSString *)repoURL {
    return repoURL;
}

- (NSString *)description {
    return description;
}
@end
