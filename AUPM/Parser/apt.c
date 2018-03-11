#include "cJSON.h"
#include <stdbool.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

#define JJJJ_INCLUDE_JSON 1 << 0

// APT LIST

typedef struct mutstr_t {
    char *str;
    size_t siz;
    size_t cap;
} mutstr_t;

static inline void str_append(mutstr_t *str, char c)
{
    if(str->siz == str->cap) {
        if(str->cap == 0) {
            str->cap = 16;
        } else {
            str->cap *= 2;
        }
        str->str = realloc(str->str, str->cap);
    }
    str->str[str->siz] = c;
    str->siz++;
}

static inline void str_set(mutstr_t *str, char *val)
{
    if(val == NULL) {
        str->str = NULL;
        str->siz = 0;
        str->cap = 0;
    } else {
        str->str = val;
        str->siz = strlen(val);
        str->cap = str->siz;
    }
}

// why didn't i just use a regex....

cJSON * jjjj_apt_list_parse(FILE *f, int *errlineno, int flags)
{
    cJSON *arr = cJSON_CreateArray();
    cJSON *lastpkg = NULL;

    cJSON *pkg = cJSON_CreateObject();
    cJSON *lastentry = NULL;

    cJSON *entry = cJSON_CreateNullString();

    mutstr_t str;
    str_set(&str, NULL);

    size_t bufcap = getpagesize();
    char buf[bufcap + 1];

    int lineno = 1;

    bool was_something = true;
    bool was_newline = true;
    bool was_colon = false;

    bool past_colon = false;
    bool reading = true;
    //bool entry_is_dud = false;
    while(reading) {
        size_t read = fread(buf, 1, bufcap, f);
        if(read < bufcap) {
            buf[read] = '\n';
            buf[read + 1] = '\n';
            read += 2;
            reading = false;
        }

        for(size_t i = 0; i < read; i++) {
            char c = buf[i];
            switch(c) {
            case '\n':
                was_colon = false;
                if(was_newline) {
                    // whitespace
                    if(lastentry == NULL) {
                        lineno++;
                        break;
                    }
                    // add pkg to arr
                    if(lastpkg) {
                        lastpkg->next = pkg;
                    } else {
                        arr->child = pkg;
                    }
                    // encode metadata
                    if(flags & JJJJ_INCLUDE_JSON) {
                        cJSON *json = cJSON_CreateNullString();
                        json->valuestring = cJSON_PrintUnformatted(pkg);
                        json->string = strdup(" json");
                        lastentry->next = json;
                        lastentry = json;
                    }

                    lastpkg = pkg;
                    pkg = cJSON_CreateObject();
                    lastentry = NULL;
                } else {
                    // add entry to pkg
                    if(entry->string == NULL) {
                        // this should error but saurik's version
                        // of APT happily just ignores it so
                        // i guess i have to go fuck myself
#ifdef JJJJ_APT_STRICT
                        cJSON_Delete(arr);
                        arr = NULL;
                        goto done;
#else
                        cJSON_Delete(entry);
#endif
                    } else {
                        str_append(&str, '\0');
                        entry->valuestring = str.str;
                        if(entry != lastentry) {
                            if(lastentry == NULL) {
                                pkg->child = entry;
                            } else {
                                lastentry->next = entry;
                            }
                            lastentry = entry;
                        }
                    }
                    entry = cJSON_CreateNullString();
                    str_set(&str, NULL);
                }
                was_newline = true;
                was_something = true;
                past_colon = false;
                lineno++;
                break;
            case ':':
                if(was_colon) {
                    break;
                }
                if(!past_colon) {
                    str_append(&str, '\0');
                    entry->string = str.str;
                    str_set(&str, NULL);
                    past_colon = true;
                    was_colon = true;
                    was_newline = false;
                    was_something = true;
                    break;
                }
            default:
                if(was_something) {
                    if(was_colon) {
                        was_colon = false;
                        was_something = false;
                        if(c == ' ') {
                            break;
                        }
                    } else if(was_newline) {
                        was_newline = false;
                        was_something = false;
                        if(c == ' ' || c == '\t') {
                            if(lastentry == NULL) {
                                cJSON_Delete(arr);
                                arr = NULL;
                                goto done;
                            }
                            cJSON_Delete(entry);
                            entry = lastentry;
                            str_set(&str, entry->valuestring);
                            str_append(&str, '\n');
                            past_colon = true;
                        }
                    }
                }
                str_append(&str, c);
            }
        }
    }
    lineno = 0;
done:
    if(errlineno != NULL) {
        *errlineno = lineno;
    }

    cJSON_Delete(pkg);
    cJSON_Delete(entry);
    free(str.str);

    return arr;
}
