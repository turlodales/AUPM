#import <Foundation/Foundation.h>
#import "cJSON.h"


cJSON * jjjj_apt_list_parse(FILE *f, int *errlineno, int flags);

id json_to_id(cJSON *json)
{
    if(json == NULL) {
        return nil;
    }

    cJSON *child;
    switch(json->type) {
    case cJSON_False:
        return [NSNumber numberWithBool:false];
    case cJSON_True:
        return [NSNumber numberWithBool:true];
    case cJSON_Number:
        return [NSNumber numberWithDouble:json->valuedouble];
    case cJSON_String:
        return [NSString stringWithUTF8String:json->valuestring];
    case cJSON_Array: {
        NSMutableArray *arr = NSMutableArray.array;
        child = json->child;
        while(child) {
            id v = json_to_id(child);
            if(v) {
                [arr addObject:json_to_id(child)];
            }
            child = child->next;
        }
        return arr;
    }
    case cJSON_Object: {
        NSMutableDictionary *dict = NSMutableDictionary.dictionary;
        child = json->child;
        while(child) {
            NSString *k = [NSString stringWithUTF8String:child->string];
            id v = json_to_id(child);
            if(k && v) {
                [dict setObject:v forKey:k];
            }
            child = child->next;
        }
        return dict;
    }
    default:
        return nil;
    }
}

id packages_to_id(const char *path)
{
    FILE *f = fopen(path, "r");
    cJSON *json = jjjj_apt_list_parse(f, NULL, 0);
    id obj = json_to_id(json);
    cJSON_Delete(json);
    return obj;
}
