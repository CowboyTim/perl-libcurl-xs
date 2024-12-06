#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <curl/curl.h>
#include <curl/easy.h>
#include <curl/multi.h>

#define THISSvOK(sv) (sv != NULL && SvROK(sv) && SvRV(sv) != &PL_sv_undef && INT2PTR(void *, SvIV(SvRV(sv))) != NULL)
#define THIS(sv)   INT2PTR(void *, SvIV(SvRV(sv)))

#define MAX_CB 20

#define CB_FIRST CB_DEBUGFUNCTION
#define CB_LAST  CB_XFERINFOFUNCTION

enum perl_cb_function {
    CB_DEBUGFUNCTION = 0,
    CB_CLOSESOCKETFUNCTION,
    CB_OPENSOCKETFUNCTION,
    CB_HEADERFUNCTION,
    CB_HSTSREADFUNCTION,
    CB_HSTSWRITEFUNCTION,
    CB_INTERLEAVEFUNCTION,
    CB_IOCTLFUNCTION,
    CB_FNMATCHFUNCTION,
    CB_PREREQFUNCTION,
    CB_PROGRESSFUNCTION,
    CB_READFUNCTION,
    CB_WRITEFUNCTION,
    CB_RESOLVER_START_FUNCTION,
    CB_SEEKFUNCTION,
    CB_SOCKOPTFUNCTION,
    CB_SSL_CTX_FUNCTION,
    CB_SSH_KEYFUNCTION,
    CB_TRAILERFUNCTION,
    CB_XFERINFOFUNCTION,
};

typedef struct {
    SV *curle;
    SV *cb[MAX_CB];
} p_curl_easy;

int cb_setup(CURL *e_http, int c_opt_f, int c_opt_d, void *cb_f, SV *cb_d){
    int r = 0;
    r = curl_easy_setopt(e_http, c_opt_d, cb_d);
    if(r != CURLE_OK){
        curl_easy_setopt(e_http, c_opt_d, NULL);
        curl_easy_setopt(e_http, c_opt_f, NULL);
        return r;
    }
    r = curl_easy_setopt(e_http, c_opt_f, cb_f);
    if(r != CURLE_OK){
        curl_easy_setopt(e_http, c_opt_d, NULL);
        curl_easy_setopt(e_http, c_opt_f, NULL);
        return r;
    }
    return r;
}

static int curl_debugfunction_cb(CURL *handle, curl_infotype type, char *data, size_t size, void *userp){
    dTHX;
    dSP;
    if(userp == NULL)
        return 0;
    SV *cb = (SV*)userp;
    if(SvTYPE(cb) != SVt_PVCV)
        return 0;
    void *p = NULL;
    int r = curl_easy_getinfo(handle, CURLINFO_PRIVATE, &p);
    if(r != CURLE_OK || !p || !((p_curl_easy *)p)->curle)
        return 0;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(((p_curl_easy *)p)->curle);
    XPUSHs(sv_2mortal(newSViv((IV)type)));
    XPUSHs(sv_2mortal(newSVpv(data, size)));
    PUTBACK;
    call_sv(cb, G_DISCARD);
    FREETMPS;
    LEAVE;
    return 0;
}

static int curl_closesocketfunction_cb(void *clientp, curl_socket_t item){
    dTHX;
    dSP;
    if(clientp == NULL)
        return 0;
    SV *cb = (SV*)clientp;
    if(SvTYPE(cb) != SVt_PVCV)
        return 0;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSViv((IV)(int)item)));
    PUTBACK;
    call_sv(cb, G_DISCARD);
    FREETMPS;
    LEAVE;
    return 0;
}

static int curl_opensocketfunction_cb(void *clientp, curlsocktype purpose, struct curl_sockaddr *address){
    dTHX;
    dSP;
    if(clientp == NULL)
        return CURL_SOCKET_BAD;
    SV *cb = (SV*)clientp;
    if(SvTYPE(cb) != SVt_PVCV)
        return CURL_SOCKET_BAD;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSViv((IV)purpose)));
    XPUSHs(sv_2mortal(newSViv((IV)address->family)));
    XPUSHs(sv_2mortal(newSViv((IV)address->socktype)));
    XPUSHs(sv_2mortal(newSViv((IV)address->protocol)));
    XPUSHs(sv_2mortal(newSViv((IV)address->addrlen)));
    PUTBACK;
    int r = call_sv(cb, G_SCALAR);
    if(r != 1)
        return CURL_SOCKET_BAD;
    SPAGAIN;
    int sock = POPi;
    FREETMPS;
    LEAVE;
    return sock;
}

static int curl_headerfunction_cb(char *data, size_t size, size_t nmemb, void *userp){
    dTHX;
    dSP;
    if(userp == NULL)
        return 0;
    SV *cb = (SV*)userp;
    if(SvTYPE(cb) != SVt_PVCV)
        return 0;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpv(data, size*nmemb)));
    PUTBACK;
    call_sv(cb, G_DISCARD);
    FREETMPS;
    LEAVE;
    return 0;
}

static int curl_hstsreadfunction_cb(char *buffer, size_t size, size_t nitems, void *userp){
    dTHX;
    dSP;
    if(userp == NULL)
        return 0;
    SV *cb = (SV*)userp;
    if(SvTYPE(cb) != SVt_PVCV)
        return 0;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpv(buffer, size*nitems)));
    PUTBACK;
    call_sv(cb, G_DISCARD);
    FREETMPS;
    LEAVE;
    return 0;
}

static int curl_hstswritefunction_cb(char *buffer, size_t size, size_t nitems, void *userp){
    dTHX;
    dSP;
    if(userp == NULL)
        return 0;
    SV *cb = (SV*)userp;
    if(SvTYPE(cb) != SVt_PVCV)
        return 0;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpv(buffer, size*nitems)));
    PUTBACK;
    call_sv(cb, G_DISCARD);
    FREETMPS;
    LEAVE;
    return 0;
}

static int curl_interleavefunction_cb(void *userp, int mask, int sock){
    dTHX;
    dSP;
    if(userp == NULL)
        return 0;
    SV *cb = (SV*)userp;
    if(SvTYPE(cb) != SVt_PVCV)
        return 0;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSViv(mask)));
    XPUSHs(sv_2mortal(newSViv(sock)));
    PUTBACK;
    call_sv(cb, G_DISCARD);
    FREETMPS;
    LEAVE;
    return 0;
}

static int curl_ioctlfunction_cb(CURL *handle, int cmd, void *clientp){
    dTHX;
    dSP;
    if(clientp == NULL)
        return 0;
    SV *cb = (SV*)clientp;
    if(SvTYPE(cb) != SVt_PVCV)
        return 0;
    void *p = NULL;
    int r = curl_easy_getinfo(handle, CURLINFO_PRIVATE, &p);
    if(r != CURLE_OK || !p || !((p_curl_easy *)p)->curle)
        return 0;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(((p_curl_easy *)p)->curle);
    XPUSHs(sv_2mortal(newSViv(cmd)));
    PUTBACK;
    call_sv(cb, G_DISCARD);
    FREETMPS;
    LEAVE;
    return 0;
}

static int curl_fnmatchfunction_cb(void *userp, const char *pattern, const char *string){
    dTHX;
    dSP;
    if(userp == NULL)
        return 0;
    SV *cb = (SV*)userp;
    if(SvTYPE(cb) != SVt_PVCV)
        return 0;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpv(pattern, 0)));
    XPUSHs(sv_2mortal(newSVpv(string, 0)));
    PUTBACK;
    int r = call_sv(cb, G_SCALAR);
    if(r != 1)
        return 0;
    SPAGAIN;
    int res = POPi;
    FREETMPS;
    LEAVE;
    return res;
}

static int curl_prereqfunction_cb(void *userp, CURL *handle){
    dTHX;
    dSP;
    if(userp == NULL)
        return 0;
    SV *cb = (SV*)userp;
    if(SvTYPE(cb) != SVt_PVCV)
        return 0;
    void *p = NULL;
    int r = curl_easy_getinfo(handle, CURLINFO_PRIVATE, &p);
    if(r != CURLE_OK || !p || !((p_curl_easy *)p)->curle)
        return 0;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(((p_curl_easy *)p)->curle);
    PUTBACK;
    int rt = call_sv(cb, G_SCALAR);
    if(rt != 1)
        return 0;
    SPAGAIN;
    int res = POPi;
    FREETMPS;
    LEAVE;
    return res;
}

static int curl_progressfunction_cb(void *userp, double dltotal, double dlnow, double ultotal, double ulnow){
    dTHX;
    dSP;
    if(userp == NULL)
        return 0;
    SV *cb = (SV*)userp;
    if(SvTYPE(cb) != SVt_PVCV)
        return 0;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVnv(dltotal)));
    XPUSHs(sv_2mortal(newSVnv(dlnow)));
    XPUSHs(sv_2mortal(newSVnv(ultotal)));
    XPUSHs(sv_2mortal(newSVnv(ulnow)));
    PUTBACK;
    int r = call_sv(cb, G_SCALAR);
    if(r != 1)
        return 0;
    SPAGAIN;
    int res = POPi;
    FREETMPS;
    LEAVE;
    return res;
}

static int curl_readfunction_cb(void *buffer, size_t size, size_t nitems, void *userp){
    dTHX;
    dSP;
    if(userp == NULL)
        return 0;
    SV *cb = (SV*)userp;
    if(SvTYPE(cb) != SVt_PVCV)
        return 0;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSViv(size*nitems)));
    PUTBACK;
    int r = call_sv(cb, G_SCALAR);
    if(r != 1)
        return 0;
    SPAGAIN;
    SV *sv = POPs;
    if(!SvPOK(sv))
        return 0;
    size_t len = SvCUR(sv);
    if(len > size*nitems)
        len = size*nitems;
    memcpy(buffer, SvPV_nolen(sv), len);
    FREETMPS;
    LEAVE;
    return len;
}

static int curl_writefunction_cb(void *buffer, size_t size, size_t nitems, void *userp){
    dTHX;
    dSP;
    if(userp == NULL)
        return 0;
    SV *cb = (SV*)userp;
    if(SvTYPE(cb) != SVt_PVCV)
        return 0;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpv(buffer, size*nitems)));
    PUTBACK;
    call_sv(cb, G_DISCARD);
    FREETMPS;
    LEAVE;
    return size*nitems;
}

static int curl_resolver_start_function_cb(void *resolver_state, void *reserved, void *userp){
    dTHX;
    dSP;
    if(userp == NULL)
        return 0;
    SV *cb = (SV*)userp;
    if(SvTYPE(cb) != SVt_PVCV)
        return 0;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSViv(PTR2IV(resolver_state))));
    PUTBACK;
    int r = call_sv(cb, G_SCALAR);
    if(r != 1)
        return 0;
    SPAGAIN;
    int res = POPi;
    FREETMPS;
    LEAVE;
    return res;
}


static int curl_seekfunction_cb(void *userp, curl_off_t offset, int origin){
    dTHX;
    dSP;
    if(userp == NULL)
        return 0;
    SV *cb = (SV*)userp;
    if(SvTYPE(cb) != SVt_PVCV)
        return 0;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSViv((IV)offset)));
    XPUSHs(sv_2mortal(newSViv((IV)origin)));
    PUTBACK;
    int r = call_sv(cb, G_SCALAR);
    if(r != 1)
        return 0;
    SPAGAIN;
    int res = POPi;
    FREETMPS;
    LEAVE;
    return res;
}

static int curl_sockoptfunction_cb(void *clientp, curl_socket_t curlfd, curlsocktype purpose){
    dTHX;
    dSP;
    if(clientp == NULL)
        return 0;
    SV *cb = (SV*)clientp;
    if(SvTYPE(cb) != SVt_PVCV)
        return 0;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSViv(PTR2IV(curlfd))));
    XPUSHs(sv_2mortal(newSViv(PTR2IV(purpose))));
    PUTBACK;
    int r = call_sv(cb, G_SCALAR);
    if(r != 1)
        return 0;
    SPAGAIN;
    int res = POPi;
    FREETMPS;
    LEAVE;
    return res;
}

static int curl_ssl_ctx_function_cb(CURL *curl, void *sslctx, void *userp){
    dTHX;
    dSP;
    if(userp == NULL)
        return 0;
    SV *cb = (SV*)userp;
    if(SvTYPE(cb) != SVt_PVCV)
        return 0;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSViv(PTR2IV(sslctx))));
    PUTBACK;
    int r = call_sv(cb, G_SCALAR);
    if(r != 1)
        return 0;
    SPAGAIN;
    int res = POPi;
    FREETMPS;
    LEAVE;
    return res;
}

static int curl_ssh_keyfunction_cb(CURL *curl, const struct curl_khkey *knownkey, const struct curl_khkey *foundkey, int khmatch, void *userp){
    dTHX;
    dSP;
    if(userp == NULL)
        return 0;
    SV *cb = (SV*)userp;
    if(SvTYPE(cb) != SVt_PVCV)
        return 0;
    if(knownkey == NULL || foundkey == NULL)
        return 0;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    if(knownkey->key)
        if(knownkey->len)
            XPUSHs(sv_2mortal(newSVpv(knownkey->key, knownkey->len)));
        else
            XPUSHs(sv_2mortal(newSVpv(knownkey->key, 0)));
    if(foundkey->key)
        if(foundkey->len)
            XPUSHs(sv_2mortal(newSVpv(foundkey->key, foundkey->len)));
        else
            XPUSHs(sv_2mortal(newSVpv(foundkey->key, 0)));
    XPUSHs(sv_2mortal(newSViv((int)(IV)khmatch)));
    PUTBACK;
    int r = call_sv(cb, G_SCALAR);
    if(r != 1)
        return 0;
    SPAGAIN;
    int res = POPi;
    FREETMPS;
    LEAVE;
    return res;
}

static int curl_trailerfunction_cb(char *data, size_t size, size_t nmemb, void *userp){
    dTHX;
    dSP;
    if(userp == NULL)
        return 0;
    SV *cb = (SV*)userp;
    if(SvTYPE(cb) != SVt_PVCV)
        return 0;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpv(data, size*nmemb)));
    PUTBACK;
    call_sv(cb, G_DISCARD);
    FREETMPS;
    LEAVE;
    return 0;
}

static int curl_xferinfofunction_cb(void *p, curl_off_t dltotal, curl_off_t dlnow, curl_off_t ultotal, curl_off_t ulnow){
    dTHX;
    dSP;
    if(p == NULL)
        return 0;
    SV *cb = (SV*)p;
    if(SvTYPE(cb) != SVt_PVCV)
        return 0;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSViv((IV)dltotal)));
    XPUSHs(sv_2mortal(newSViv((IV)dlnow)));
    XPUSHs(sv_2mortal(newSViv((IV)ultotal)));
    XPUSHs(sv_2mortal(newSViv((IV)ulnow)));
    PUTBACK;
    int r = call_sv(cb, G_SCALAR);
    if(r != 1)
        return 0;
    SPAGAIN;
    int res = POPi;
    FREETMPS;
    LEAVE;
    return res;
}


MODULE = utils::curl                PACKAGE = http           PREFIX = L_

VERSIONCHECK: DISABLE
PROTOTYPES: DISABLE

BOOT:
{
        HV *stash = gv_stashpv("http", 0);
        newCONSTSUB(stash, "CURLPAUSE_RECV"             , newSViv(CURLPAUSE_RECV));
        newCONSTSUB(stash, "CURLPAUSE_RECV_CONT"        , newSViv(CURLPAUSE_RECV_CONT));
        newCONSTSUB(stash, "CURLPAUSE_SEND"             , newSViv(CURLPAUSE_SEND));
        newCONSTSUB(stash, "CURLPAUSE_SEND_CONT"        , newSViv(CURLPAUSE_SEND_CONT));
        newCONSTSUB(stash, "CURLPAUSE_ALL"              , newSViv(CURLPAUSE_ALL));
        newCONSTSUB(stash, "CURLPAUSE_CONT"             , newSViv(CURLPAUSE_CONT));
        newCONSTSUB(stash, "CURL_GLOBAL_DEFAULT"        , newSViv(CURL_GLOBAL_DEFAULT));
        newCONSTSUB(stash, "CURL_GLOBAL_ALL"            , newSViv(CURL_GLOBAL_ALL));
        newCONSTSUB(stash, "CURL_GLOBAL_ACK_EINTR"      , newSViv(CURL_GLOBAL_ACK_EINTR));
        newCONSTSUB(stash, "CURL_GLOBAL_NOTHING"        , newSViv(CURL_GLOBAL_NOTHING));
        newCONSTSUB(stash, "CURL_GLOBAL_SSL"            , newSViv(CURL_GLOBAL_SSL));
        newCONSTSUB(stash, "CURL_GLOBAL_WIN32"          , newSViv(CURL_GLOBAL_WIN32));
        newCONSTSUB(stash, "CURL_CSELECT_IN"            , newSViv(CURL_CSELECT_IN));
        newCONSTSUB(stash, "CURL_CSELECT_OUT"           , newSViv(CURL_CSELECT_OUT));
        newCONSTSUB(stash, "CURL_CSELECT_ERR"           , newSViv(CURL_CSELECT_ERR));
        newCONSTSUB(stash, "CURL_POLL_NONE"             , newSViv(CURL_POLL_NONE));
        newCONSTSUB(stash, "CURL_POLL_IN"               , newSViv(CURL_POLL_IN));
        newCONSTSUB(stash, "CURL_POLL_OUT"              , newSViv(CURL_POLL_OUT));
        newCONSTSUB(stash, "CURL_POLL_INOUT"            , newSViv(CURL_POLL_INOUT));
        newCONSTSUB(stash, "CURL_POLL_REMOVE"           , newSViv(CURL_POLL_REMOVE));
        newCONSTSUB(stash, "CURLPIPE_NOTHING"           , newSViv(CURLPIPE_NOTHING));
        newCONSTSUB(stash, "CURLPIPE_HTTP1"             , newSViv(CURLPIPE_HTTP1));
        newCONSTSUB(stash, "CURLPIPE_MULTIPLEX"         , newSViv(CURLPIPE_MULTIPLEX));
        newCONSTSUB(stash, "CURL_WAIT_POLLIN"           , newSViv(CURL_WAIT_POLLIN));
        newCONSTSUB(stash, "CURL_WAIT_POLLPRI"          , newSViv(CURL_WAIT_POLLPRI));
        newCONSTSUB(stash, "CURL_WAIT_POLLOUT"          , newSViv(CURL_WAIT_POLLOUT));
        newCONSTSUB(stash, "CURL_PUSH_OK"               , newSViv(CURL_PUSH_OK));
        newCONSTSUB(stash, "CURL_PUSH_DENY"             , newSViv(CURL_PUSH_DENY));
#if (LIBCURL_VERSION_NUM >= 0x073f00)
        newCONSTSUB(stash, "CURL_PUSH_ERROROUT"         , newSViv(CURL_PUSH_ERROROUT));
#else
        newCONSTSUB(stash, "CURL_PUSH_ERROROUT"         , newSViv(2));
#endif
        int r = curl_global_init(CURL_GLOBAL_DEFAULT);
        if(r != 0)
            croak("curl_global_init failed: %d", r);
}

INCLUDE: ../../curl_constants.xsh

#ifndef CURLOPTTYPE_BLOB
#define CURLOPTTYPE_BLOB 40000
#endif

void L_curl_global_init(int flags=CURL_GLOBAL_DEFAULT)
    PREINIT:
        int r;
    CODE:
        dTHX;
        dSP;
        r = curl_global_init(flags);
        if(r != 0)
            XSRETURN_NO;
        XSRETURN_YES;

void L_curl_global_cleanup()
    CODE:
        dTHX;
        dSP;
        curl_global_cleanup();
        XSRETURN_YES;

void L_curl_global_trace(...)
    PREINIT:
    PPCODE:
        dTHX;
#if (LIBCURL_VERSION_NUM >= 0x080000)
        dSP;
        SV *config = NULL;
        int r = 0;
        if(items < 1)
            XSRETURN_UNDEF;
        config = POPs;
        if(!config || !SvPOK(config))
            XSRETURN_UNDEF;
        r = curl_global_trace(SvPV_nolen(config));
        if(r != 0)
            XSRETURN_IV(r);
        XSRETURN_IV(r);
#else
    XSRETURN_UNDEF;
#endif

void L_curl_getdate(...)
    SV *datestr=NULL;
    PREINIT:
        time_t t = 0;
    PPCODE:
        dTHX;
        dSP;
        datestr = POPs;
        if(!datestr || !SvPOK(datestr))
            XSRETURN_UNDEF;
        t = curl_getdate(SvPV_nolen(datestr), NULL);
        if(t == -1)
            XSRETURN_UNDEF;
        XSRETURN_UV(t);

void L_curl_version_info(...)
    PREINIT:
#if (LIBCURL_VERSION_NUM <= 0x073d01)
        curl_version_info_data *vi = NULL;
#else
        struct curl_version_info_data *vi = NULL;
#endif
        HV *rh = NULL;
    PPCODE:
        dTHX;
        dSP;
        vi = curl_version_info(CURLVERSION_NOW);
        if(!vi)
            XSRETURN_UNDEF;
        rh = (HV *)sv_2mortal((SV *)newHV());
        hv_store(rh, "version"        ,  7, newSVpv(vi->version, 0)          , 0);
        hv_store(rh, "version_num"    , 11, newSViv(vi->version_num)         , 0);
        hv_store(rh, "host"           ,  4, newSVpv(vi->host, 0)             , 0);
        hv_store(rh, "features"       ,  8, newSViv(vi->features)            , 0);
        hv_store(rh, "ssl_version"    , 11, newSVpv(vi->ssl_version, 0)      , 0);
        hv_store(rh, "ssl_version_num", 15, newSViv(vi->ssl_version_num)     , 0);
        hv_store(rh, "libz_version"   , 12, newSVpv(vi->libz_version, 0)     , 0);
        AV *protocols = newAV();
        for(int i=0; vi->protocols[i]; i++){
            av_push(protocols, newSVpv(vi->protocols[i], 0));
        }
        hv_store(rh, "protocols"      ,  9, newRV_inc((SV *)protocols)       , 0);
        XPUSHs(newRV_inc((SV *)rh));

void L_curl_version(...)
    PPCODE:
        dTHX;
        dSP;
        XPUSHs(sv_2mortal(newSVpv(curl_version(), 0)));


void L_curl_easy_init()
    PPCODE:
        dTHX;
        dSP;
        CURL *c = curl_easy_init();
        if(!c)
            XSRETURN_NO;
        SV *sv = sv_newmortal();
        SvPOK_only(sv);
        sv_setref_pv(sv, "http::curl::easy", (void *)c);
        SvREADONLY_on(sv);
        XPUSHs(sv);
        void *ptr = NULL;
        Newxz(ptr, 1, p_curl_easy);
        //printf("c: %p, %p\n", c, ptr);
        ((p_curl_easy *)ptr)->curle = SvRV(sv); // no need to increase refcount
        int t = curl_easy_setopt(c, CURLOPT_PRIVATE, ptr);
        if(t != CURLE_OK)
            croak("curl_easy_setopt CURLOPT_PRIVATE failed: %d", t);

void L_curl_easy_cleanup(SV *e_http=NULL)
    PPCODE:
        dTHX;
        dSP;
        POPs;
        if(!THISSvOK(e_http))
            XSRETURN_UNDEF;
        //printf("e: %p\n", (CURL *)THIS(e_http));
        sv_setref_pv(e_http, NULL, NULL);
        XSRETURN_UNDEF;

void L_curl_easy_reset(SV *e_http=NULL)
    PPCODE:
        dTHX;
        dSP;
        if(!THISSvOK(e_http))
            XSRETURN_UNDEF;
        curl_easy_reset((CURL *)THIS(e_http));
        XSRETURN_UNDEF;

void L_curl_easy_strerror(int code)
    PPCODE:
        dTHX;
        dSP;
        const char *s = curl_easy_strerror(code);
        if(!s)
            XSRETURN_UNDEF;
        XPUSHs(sv_2mortal(newSVpv(s, 0)));

void L_curl_easy_setopt(SV *e_http=NULL, int c_opt=0, SV *value=&PL_sv_undef)
    PREINIT:
        int r = -1;
    PPCODE:
        dTHX;
        dSP;
        if(!THISSvOK(e_http))
            XSRETURN_UNDEF;
        if(value == NULL)
            XSRETURN_UNDEF;

        if(c_opt >= CURLOPTTYPE_LONG && c_opt < CURLOPTTYPE_OBJECTPOINT){
            long _vl = (long)SvIV(value);
        //printf("p1: %lld, %p, f: %d & %d\n", (long long)SvIV(SvRV(e_http)), THIS(e_http), c_opt, CURLOPT_URL);
            r = curl_easy_setopt((CURL *)THIS(e_http), c_opt, _vl);
        } else if(c_opt >= CURLOPTTYPE_OBJECTPOINT && c_opt < CURLOPTTYPE_FUNCTIONPOINT){
            if(!SvPOK(value))
                XSRETURN_UNDEF;
        //printf("p2: %lld, %p, f: %d & %d\n", (long long)SvIV(SvRV(e_http)), THIS(e_http), c_opt, CURLOPT_URL);
            char *_vc = (char *)SvPV_nolen(value);
            r = curl_easy_setopt((CURL *)THIS(e_http), c_opt, _vc);
        } else if(c_opt >= CURLOPTTYPE_FUNCTIONPOINT && c_opt < CURLOPTTYPE_OFF_T){
            int cb_indx = -1;
            if(!SvROK(value))
                XSRETURN_UNDEF;
            SV *cb = SvRV(value);
            //printf("CALLBACK: %p, %p, %d, %d, %d\n", cb, value, SvTYPE(cb), SvTYPE(value), SVt_PVCV);
            if(SvTYPE(cb) != SVt_PVCV)
                XSRETURN_UNDEF;
            // deprecated, same as CURLOPT_XFERINFOFUNCTION, even the defined value
            if(c_opt == CURLOPT_PROGRESSFUNCTION
            || c_opt == CURLOPT_PROGRESSDATA){
                r = cb_setup((CURL *)THIS(e_http), c_opt, CURLOPT_PROGRESSDATA, curl_progressfunction_cb, cb);
                cb_indx = CB_PROGRESSFUNCTION;
            } else {
            switch(c_opt){
                case CURLOPT_HEADERFUNCTION:
                case CURLOPT_HEADERDATA:
                    r = cb_setup((CURL *)THIS(e_http), CURLOPT_HEADERFUNCTION, CURLOPT_HEADERDATA, curl_headerfunction_cb, cb);
                    cb_indx = CB_HEADERFUNCTION;
                    break;
                case CURLOPT_DEBUGFUNCTION:
                case CURLOPT_DEBUGDATA:
                    r = cb_setup((CURL *)THIS(e_http), CURLOPT_DEBUGFUNCTION, CURLOPT_DEBUGDATA, curl_debugfunction_cb, cb);
                    cb_indx = CB_DEBUGFUNCTION;
                    break;
                case CURLOPT_HSTSREADFUNCTION:
                case CURLOPT_HSTSREADDATA:
                    r = cb_setup((CURL *)THIS(e_http), CURLOPT_HSTSREADFUNCTION, CURLOPT_HSTSREADDATA, curl_hstsreadfunction_cb, cb);
                    cb_indx = CB_HSTSREADFUNCTION;
                    break;
                case CURLOPT_HSTSWRITEFUNCTION:
                case CURLOPT_HSTSWRITEDATA:
                    r = cb_setup((CURL *)THIS(e_http), CURLOPT_HSTSWRITEFUNCTION, CURLOPT_HSTSWRITEDATA, curl_hstswritefunction_cb, cb);
                    cb_indx = CB_HSTSWRITEFUNCTION;
                    break;
                case CURLOPT_INTERLEAVEFUNCTION:
                case CURLOPT_INTERLEAVEDATA:
                    r = cb_setup((CURL *)THIS(e_http), CURLOPT_INTERLEAVEFUNCTION, CURLOPT_INTERLEAVEDATA, curl_interleavefunction_cb, cb);
                    cb_indx = CB_INTERLEAVEFUNCTION;
                    break;
                case CURLOPT_IOCTLFUNCTION:
                case CURLOPT_IOCTLDATA:
                    r = cb_setup((CURL *)THIS(e_http), CURLOPT_IOCTLFUNCTION, CURLOPT_IOCTLDATA, curl_ioctlfunction_cb, cb);
                    cb_indx = CB_IOCTLFUNCTION;
                    break;
                case CURLOPT_FNMATCH_FUNCTION:
                case CURLOPT_FNMATCH_DATA:
                    r = cb_setup((CURL *)THIS(e_http), CURLOPT_FNMATCH_FUNCTION, CURLOPT_FNMATCH_DATA, curl_fnmatchfunction_cb, cb);
                    cb_indx = CB_FNMATCHFUNCTION;
                    break;
                case CURLOPT_TRAILERFUNCTION:
                case CURLOPT_TRAILERDATA:
                    r = cb_setup((CURL *)THIS(e_http), CURLOPT_TRAILERFUNCTION, CURLOPT_TRAILERDATA, curl_trailerfunction_cb, cb);
                    cb_indx = CB_TRAILERFUNCTION;
                    break;
                case CURLOPT_XFERINFOFUNCTION:
                case CURLOPT_XFERINFODATA:
                    r = cb_setup((CURL *)THIS(e_http), CURLOPT_XFERINFOFUNCTION, CURLOPT_XFERINFODATA, curl_xferinfofunction_cb, cb);
                    cb_indx = CB_XFERINFOFUNCTION;
                    break;
                case CURLOPT_READFUNCTION:
                case CURLOPT_READDATA:
                    r = cb_setup((CURL *)THIS(e_http), CURLOPT_READFUNCTION, CURLOPT_READDATA, curl_readfunction_cb, cb);
                    cb_indx = CB_READFUNCTION;
                    break;
                case CURLOPT_WRITEFUNCTION:
                case CURLOPT_WRITEDATA:
                    r = cb_setup((CURL *)THIS(e_http), CURLOPT_WRITEFUNCTION, CURLOPT_WRITEDATA, curl_writefunction_cb, cb);
                    cb_indx = CB_WRITEFUNCTION;
                    break;
                case CURLOPT_SOCKOPTFUNCTION:
                case CURLOPT_SOCKOPTDATA:
                    r = cb_setup((CURL *)THIS(e_http), CURLOPT_SOCKOPTFUNCTION, CURLOPT_SOCKOPTDATA, curl_sockoptfunction_cb, cb);
                    cb_indx = CB_SOCKOPTFUNCTION;
                    break;
                case CURLOPT_SSL_CTX_FUNCTION:
                case CURLOPT_SSL_CTX_DATA:
                    r = cb_setup((CURL *)THIS(e_http), CURLOPT_SSL_CTX_FUNCTION, CURLOPT_SSL_CTX_DATA, curl_ssl_ctx_function_cb, cb);
                    cb_indx = CB_SSL_CTX_FUNCTION;
                    break;
                case CURLOPT_SSH_KEYFUNCTION:
                case CURLOPT_SSH_KEYDATA:
                    r = cb_setup((CURL *)THIS(e_http), CURLOPT_SSH_KEYFUNCTION, CURLOPT_SSH_KEYDATA, curl_ssh_keyfunction_cb, cb);
                    cb_indx = CB_SSH_KEYFUNCTION;
                    break;
                case CURLOPT_RESOLVER_START_FUNCTION:
                case CURLOPT_RESOLVER_START_DATA:
                    r = cb_setup((CURL *)THIS(e_http), CURLOPT_RESOLVER_START_FUNCTION, CURLOPT_RESOLVER_START_DATA, curl_resolver_start_function_cb, cb);
                    cb_indx = CB_RESOLVER_START_FUNCTION;
                    break;
                case CURLOPT_SEEKFUNCTION:
                case CURLOPT_SEEKDATA:
                    r = cb_setup((CURL *)THIS(e_http), CURLOPT_SEEKFUNCTION, CURLOPT_SEEKDATA, curl_seekfunction_cb, cb);
                    cb_indx = CB_SEEKFUNCTION;
                    break;
                default:
                    XSRETURN_UNDEF;
            }
            }
            if(r == CURLE_OK){
                if(cb_indx != -1){
                    void *p = NULL;
                    int t = curl_easy_getinfo((CURL *)THIS(e_http), CURLINFO_PRIVATE, &p);
                    //printf("t: %p, %d, %d %d: %p\n", THIS(e_http), t, r, cb_indx, p);
                    if(t == CURLE_OK && p){
                        //printf("p: %p, %p, %d\n", p, (void *)((p_curl_easy *)p)->cb[cb_indx], cb_indx);
                        SV *ptr = ((p_curl_easy *)p)->cb[cb_indx];
                        if(ptr)
                            SvREFCNT_dec(ptr);
                        ((p_curl_easy *)p)->cb[cb_indx] = cb;
                    }
                } else {
                    croak("Invalid callback index: INTERNAL ERROR");
                }
                SvREFCNT_inc(cb);
            }
        } else if(c_opt >= CURLOPTTYPE_OFF_T && c_opt < CURLOPTTYPE_BLOB){
            long _vo = (curl_off_t)SvIV(value);
        //printf("p3: %lld, %p, f: %d & %d\n", (long long)SvIV(SvRV(e_http)), THIS(e_http), c_opt, CURLOPT_URL);
            r = curl_easy_setopt((CURL *)THIS(e_http), c_opt, _vo);
        } else {
            XSRETURN_UNDEF;
        }
        if(r != CURLE_OK)
            XSRETURN_IV(r);
        XSRETURN_IV(r);

void L_curl_easy_option_by_name(...)
    PPCODE:
        dTHX;
#if (LIBCURL_VERSION_NUM >= 0x073f00)
        dSP;
        SV *name = POPs;
        if(!name || !SvPOK(name))
            XSRETURN_UNDEF;
        const struct curl_easyoption *opt = curl_easy_option_by_name(SvPV_nolen(name));
        if(!opt){
            XSRETURN_UNDEF;
        }
        HV *rh = (HV *)sv_2mortal((SV *)newHV());
        hv_store(rh, "name"  , 4, newSVpv(opt->name, 0), 0);
        hv_store(rh, "type"  , 4, newSViv(opt->type)   , 0);
        hv_store(rh, "flags" , 5, newSViv(opt->flags)  , 0);
        hv_store(rh, "id"    , 2, newSViv(opt->id)     , 0);
        XPUSHs(newRV_inc((SV *)rh));
#else
        croak("curl_easy_option_by_name is not supported in this version of libcurl");
#endif

void L_curl_easy_option_by_id(...)
    PPCODE:
        dTHX;
#if (LIBCURL_VERSION_NUM >= 0x073f00)
        dSP;
        SV *id = POPs;
        if(!id || !SvPOK(id))
            XSRETURN_UNDEF;
        const struct curl_easyoption *opt = curl_easy_option_by_id(SvIV(id));
        if(!opt)
            XSRETURN_UNDEF;
        HV *rh = (HV *)sv_2mortal((SV *)newHV());
        hv_store(rh, "name"  , 4, newSVpv(opt->name, 0), 0);
        hv_store(rh, "type"  , 4, newSViv(opt->type)   , 0);
        hv_store(rh, "flags" , 5, newSViv(opt->flags)  , 0);
        hv_store(rh, "id"    , 2, newSViv(opt->id)     , 0);
        XPUSHs(newRV_inc((SV *)rh));
#else
        croak("curl_easy_option_by_id is not supported in this version of libcurl");
#endif

void L_curl_easy_perform(SV *e_http=NULL)
    PREINIT:
        int r;
    PPCODE:
        dTHX;
        dSP;
        if(!THISSvOK(e_http))
            XSRETURN_UNDEF;
        r = curl_easy_perform((CURL *)THIS(e_http));
        if(r != CURLE_OK)
            XSRETURN_IV(r);
        XSRETURN_IV(0);

void L_curl_easy_duphandle(SV *e_http=NULL)
    PPCODE:
        dTHX;
        dSP;
        if(!THISSvOK(e_http))
            XSRETURN_UNDEF;
        CURL *c = curl_easy_duphandle((CURL *)THIS(e_http));
        if(!c)
            XSRETURN_NO;
        SV *sv = sv_newmortal();
        sv_setref_pv(sv, "http::curl::easy", (void *)c);
        SvREADONLY_on(sv);
        XPUSHs(sv);

        // don't fetch CURLOPT_PRIVATE, curl_easy_duphandle copies it, but we
        // won't do anything with it, as it's part of the original e_http
        // handle: also DON'T clear that, just the ptr
        void *ptr = NULL;
        Newxz(ptr, 1, p_curl_easy);
        int d = curl_easy_setopt(c, CURLOPT_PRIVATE, ptr);
        if(d != CURLE_OK){
            croak("curl_easy_setopt CURLOPT_PRIVATE failed: %d", d);
        }
        ((p_curl_easy *)ptr)->curle = SvRV(sv); // no need to increase refcount
        //printf("d: %lld, %p, %p\n", (long long)c, c, ptr);

        // fetch from the original handle the FUNCTION opts
        void *p = NULL;
        int r = curl_easy_getinfo((CURL *)THIS(e_http), CURLINFO_PRIVATE, &p);
        if(r == CURLE_OK && p){
            for(int f=CB_FIRST; f<CB_LAST; f++){
                if(((p_curl_easy *)p)->cb[f]){
                    SvREFCNT_inc((SV *)((p_curl_easy *)p)->cb[f]);
                    ((p_curl_easy *)ptr)->cb[f] = ((p_curl_easy *)p)->cb[f];
                }
            }
        }

void L_curl_easy_escape(...)
    SV *url=NULL;
    PREINIT:
        char *s = NULL;
    PPCODE:
        dTHX;
        dSP;
        if(items < 1)
            XSRETURN_UNDEF;
        url = POPs;
        if(!url || !SvPOK(url))
            XSRETURN_UNDEF;
#if (LIBCURL_VERSION_NUM >= 0x075100)
        s = curl_easy_escape(NULL, SvPV_nolen(url), SvCUR(url));
#else
        CURL *c = curl_easy_init();
        if(!c)
            XSRETURN_UNDEF;
        s = curl_easy_escape(c, SvPV_nolen(url), SvCUR(url));
        curl_easy_cleanup(c);
#endif
        if(!s)
            XSRETURN_UNDEF;
        SV *sv = sv_2mortal(newSVpv(s, 0));
        curl_free(s);
        XPUSHs(sv);

void L_curl_easy_unescape(...)
    SV *url=NULL;
    PREINIT:
        char *s = NULL;
    PPCODE:
        dTHX;
        dSP;
        if(items < 1)
            XSRETURN_UNDEF;
        url = POPs;
        if(!url || !SvPOK(url))
            XSRETURN_UNDEF;
#if (LIBCURL_VERSION_NUM >= 0x075100)
        s = curl_easy_unescape(NULL, SvPV_nolen(url), SvCUR(url), NULL);
#else
        CURL *c = curl_easy_init();
        if(!c)
            XSRETURN_UNDEF;
        s = curl_easy_unescape(c, SvPV_nolen(url), SvCUR(url), NULL);
        curl_easy_cleanup(c);
#endif
        if(!s)
            XSRETURN_UNDEF;
        SV *sv = sv_2mortal(newSVpv(s, 0));
        curl_free(s);
        XPUSHs(sv);

void L_curl_easy_getinfo(SV *e_http=NULL, int c_info=0)
    PREINIT:
        long l = 0;
        curl_off_t o = 0;
        int r = 0;
        double d = 0;
        char *s = NULL;
    PPCODE:
        dTHX;
        dSP;
        if(!THISSvOK(e_http))
            XSRETURN_UNDEF;
        if(c_info == 0)
            XSRETURN_UNDEF;
        if(c_info >= CURLINFO_STRING && c_info < CURLINFO_LONG){
            r = curl_easy_getinfo((CURL *)THIS(e_http), c_info, &s);
            if(r != CURLE_OK)
                XSRETURN_UNDEF;
            ST(0) = sv_2mortal(newSVpv(s, 0));
            XSRETURN(1);
        } else if(c_info >= CURLINFO_LONG && c_info < CURLINFO_DOUBLE){
            r = curl_easy_getinfo((CURL *)THIS(e_http), c_info, &l);
            if(r != CURLE_OK)
                XSRETURN_UNDEF;
            XSRETURN_IV(l);
        } else if(c_info >= CURLINFO_DOUBLE && c_info < CURLINFO_SLIST){
            r = curl_easy_getinfo((CURL *)THIS(e_http), c_info, &d);
            if(r != CURLE_OK)
                XSRETURN_UNDEF;
            XSRETURN_NV(d);
        } else if(c_info >= CURLINFO_PTR && c_info < CURLINFO_SOCKET){
            r = curl_easy_getinfo((CURL *)THIS(e_http), c_info, &l);
            if(r != CURLE_OK)
                XSRETURN_UNDEF;
            XSRETURN_IV(l);
        } else if(c_info >= CURLINFO_SOCKET && c_info < CURLINFO_OFF_T){
            r = curl_easy_getinfo((CURL *)THIS(e_http), c_info, &l);
            if(r != CURLE_OK)
                XSRETURN_UNDEF;
            XSRETURN_IV(l);
        } else if(c_info >= CURLINFO_OFF_T){
            r = curl_easy_getinfo((CURL *)THIS(e_http), c_info, &o);
            if(r != CURLE_OK)
                XSRETURN_UNDEF;
            XSRETURN_IV((IV)((long)o));
        } else {
            XSRETURN_UNDEF;
        }

void L_curl_easy_pause(SV *e_http=NULL, int bitmask=0)
    PREINIT:
        int r = 0;
    PPCODE:
        dTHX;
        dSP;
        if(!THISSvOK(e_http))
            XSRETURN_UNDEF;
        r = curl_easy_pause((CURL *)THIS(e_http), bitmask);
        if(r != CURLE_OK)
            XSRETURN_IV(r);
        XSRETURN_IV(0);

void L_curl_easy_upkeep(SV *e_http=NULL)
    PREINIT:
        int r = 0;
    PPCODE:
        dTHX;
#if (LIBCURL_VERSION_NUM >= 0x073f00)
        dSP;
        if(!THISSvOK(e_http))
            XSRETURN_UNDEF;
        r = curl_easy_upkeep((CURL *)THIS(e_http));
        if(r != CURLE_OK)
            XSRETURN_IV(r);
        XSRETURN_IV(0);
#else
        croak("curl_easy_upkeep is not supported in this version of libcurl");
#endif

void L_curl_easy_send(SV *e_http=NULL, SV *data=&PL_sv_undef, )
    PREINIT:
        int r = 0;
        size_t sent_sz = 0;
    PPCODE:
        dTHX;
        dSP;
        if(!THISSvOK(e_http))
            XSRETURN_UNDEF;
        if(!data || !SvPOK(data))
            XSRETURN_UNDEF;
        r = curl_easy_send((CURL *)THIS(e_http), SvPV_nolen(data), SvCUR(data), &sent_sz);
        if(r != CURLE_OK)
            XSRETURN_IV(r);
        //printf("data: %s %d\n", SvPV_nolen(data), sent_sz);
        XSRETURN_IV(0);

void L_curl_easy_recv(SV *e_http=NULL, SV *data=&PL_sv_undef, IV max_sz=0)
    PREINIT:
        int r = 0;
        size_t recv_sz = 0;
    PPCODE:
        dTHX;
        dSP;
        if(!THISSvOK(e_http))
            XSRETURN_UNDEF;
        if(!data || !SvPOK(data) || data == &PL_sv_undef)
            XSRETURN_UNDEF;
        if(max_sz == 0)
            XSRETURN_IV(0);
        SV *buf = newSV(max_sz);
        SvPOK_only(buf);
        r = curl_easy_recv((CURL *)THIS(e_http), SvPV_nolen(buf), max_sz, &recv_sz);
        if(r != CURLE_OK)
            XSRETURN_IV(r);
        buf = sv_2mortal(buf);
        SvCUR_set(buf, recv_sz);
        sv_catsv_nomg(data, buf);
        XSRETURN_IV(0);

void L_curl_multi_init()
    PPCODE:
        dTHX;
        dSP;
        CURLM *m = curl_multi_init();
        if(!m)
            XSRETURN_NO;
        SV *sv = sv_newmortal();
        sv_setref_pv(sv, "http::curl::multi", (void *)m);
        SvREADONLY_on(sv);
        XPUSHs(sv);

void L_curl_multi_cleanup(SV *m_http=NULL)
    PREINIT:
        int r = 0;
    PPCODE:
        dTHX;
        dSP;
        if(!THISSvOK(m_http))
            XSRETURN_UNDEF;
        //printf("m: %p\n", (CURLM *)THIS(m_http));
        // go via DESTROY, as we have to destroy SV's too
        sv_setref_pv(m_http, NULL, NULL);
        XSRETURN_IV(0);

void L_curl_multi_wakeup(SV *m_http=NULL)
    PPCODE:
        dTHX;
#if (LIBCURL_VERSION_NUM >= 0x073f00)
        dSP;
        if(!THISSvOK(m_http))
            XSRETURN_UNDEF;
        int r = curl_multi_wakeup((CURLM *)THIS(m_http));
        XSRETURN_IV(r);
#else
        croak("curl_multi_wakeup is not supported in this version of libcurl");
#endif

void L_curl_multi_perform(SV *m_http=NULL, SV *running_handles=NULL)
    PREINIT:
        int r = 0;
        int h = 0;
    PPCODE:
        dTHX;
        dSP;
        if(!THISSvOK(m_http))
            XSRETURN_UNDEF;
        //printf("PERFORM: %p\n", (CURLM *)THIS(m_http));
        r = curl_multi_perform((CURLM *)THIS(m_http), &h);
        if(r != CURLM_OK)
            XSRETURN_IV(r);
        if(running_handles != NULL){
            sv_setiv(running_handles, h);
        }
        XSRETURN_IV(r);

void L_curl_multi_add_handle(SV *m_http=NULL, SV *e_http=NULL)
    PPCODE:
        dTHX;
        dSP;
        if(!THISSvOK(m_http))
            XSRETURN_UNDEF;
        if(!THISSvOK(e_http))
            XSRETURN_UNDEF;
        //printf("ADD: %p, %p\n", (CURLM *)THIS(m_http), (CURL *)THIS(e_http));
        int r = curl_multi_add_handle((CURLM *)THIS(m_http), (CURL *)THIS(e_http));
        if(r != CURLM_OK)
            XSRETURN_IV(r);
        SvREFCNT_inc(SvRV(e_http));
        XSRETURN_IV(r);

void L_curl_multi_remove_handle(SV *m_http=NULL, SV *e_http=NULL)
    PPCODE:
        dTHX;
        dSP;
        if(!THISSvOK(m_http))
            XSRETURN_UNDEF;
        if(!THISSvOK(e_http))
            XSRETURN_UNDEF;
        int r = curl_multi_remove_handle((CURLM *)THIS(m_http), (CURL *)THIS(e_http));
        if(r != CURLM_OK)
            XSRETURN_IV(r);
        if(SvREFCNT(SvRV(e_http)) > 1)
            SvREFCNT_dec(SvRV(e_http));
        XSRETURN_IV(r);

void L_curl_multi_strerror(int code)
    PPCODE:
        dTHX;
        dSP;
        const char *s = curl_multi_strerror(code);
        if(!s)
            XSRETURN_UNDEF;
        XPUSHs(sv_2mortal(newSVpv(s, 0)));

void L_curl_multi_timeout(SV *m_http=NULL, SV *timeout = NULL)
    PREINIT:
        long l = 0;
    PPCODE:
        dTHX;
        dSP;
        if(!THISSvOK(m_http))
            XSRETURN_UNDEF;
        int r = curl_multi_timeout((CURLM *)THIS(m_http), &l);
        if(r != CURLM_OK)
            XSRETURN_IV(r);
        if(timeout != NULL){
            sv_setiv(timeout, l);
        }
        XSRETURN_IV(r);

void L_curl_multi_info_read(SV *m_http=NULL, SV *msgs_in_queue=NULL)
    PREINIT:
        int r = 0;
    PPCODE:
        dTHX;
        dSP;
        if(!THISSvOK(m_http))
            XSRETURN_UNDEF;
        CURLMsg *m = curl_multi_info_read((CURLM *)THIS(m_http), &r);
        if(msgs_in_queue != NULL){
            sv_setiv(msgs_in_queue, r);
        }
        if(!m)
            XSRETURN_UNDEF;
        HV *rh = (HV*)sv_2mortal((SV*)newHV());
        hv_store(rh, "msg"   ,3,newSViv(m->msg)        ,0);
        hv_store(rh, "result",6,newSViv(m->data.result),0);
        XPUSHs(newRV((SV*)rh));

void L_curl_multi_setopt(SV *m_http=NULL, IV c_opt=0, SV *value=NULL)
    PREINIT:
        int r = -1;
    PPCODE:
        dTHX;
        dSP;
        if(!THISSvOK(m_http))
            XSRETURN_UNDEF;
        if(!value || !SvOK(value))
            XSRETURN_UNDEF;

        if(c_opt >= CURLOPTTYPE_LONG && c_opt < CURLOPTTYPE_OBJECTPOINT){
            long _vl = (long)SvIV(value);
            r = curl_multi_setopt((CURLM *)THIS(m_http), c_opt, _vl);
        } else if(c_opt >= CURLOPTTYPE_OBJECTPOINT && c_opt < CURLOPTTYPE_FUNCTIONPOINT){
            if(!SvPOK(value))
                XSRETURN_UNDEF;
            char *_vc = (char *)SvPV_nolen(value);
            r = curl_multi_setopt((CURLM *)THIS(m_http), c_opt, _vc);
        } else if(c_opt >= CURLOPTTYPE_FUNCTIONPOINT && c_opt < CURLOPTTYPE_OFF_T){
            XSRETURN_UNDEF;
        } else if(c_opt >= CURLOPTTYPE_OFF_T && c_opt < CURLOPTTYPE_BLOB){
            long _vb = (long)SvIV(value);
            r = curl_multi_setopt((CURLM *)THIS(m_http), c_opt, _vb);
        } else {
            XSRETURN_UNDEF;
        }
        XSRETURN_IV(r);

void L_curl_multi_fdset(SV *m_http=NULL)
    PREINIT:
        fd_set r;
        fd_set w;
        fd_set e;
        int max = 0;
        int rt = 0;
    PPCODE:
        dTHX;
        dSP;
        if(!THISSvOK(m_http))
            XSRETURN_UNDEF;
        rt = curl_multi_fdset((CURLM *)THIS(m_http), &r, &w, &e, &max);
        if(rt != CURLM_OK)
            XSRETURN_IV(rt);
        AV *re = (AV *)sv_2mortal((SV *)newAV());
        AV *we = (AV *)sv_2mortal((SV *)newAV());
        AV *ee = (AV *)sv_2mortal((SV *)newAV());
        for(int i=0; i<max; i++){
            if(FD_ISSET(i, &r))
                av_push(re, newSViv(i));
            if(FD_ISSET(i, &w))
                av_push(we, newSViv(i));
            if(FD_ISSET(i, &e))
                av_push(ee, newSViv(i));
        }
        XPUSHs(newRV_noinc((SV *)re));
        XPUSHs(newRV_noinc((SV *)we));
        XPUSHs(newRV_noinc((SV *)ee));

void L_curl_multi_poll(SV *m_http=NULL, SV *extrafds=&PL_sv_undef, int timeout=0, SV *numfds=NULL)
    PPCODE:
        dTHX;
#if (LIBCURL_VERSION_NUM >= 0x073f00)
        dSP;
        int r = 0;
        int nfds = 0;
        if(!THISSvOK(m_http))
            XSRETURN_UNDEF;
        r = curl_multi_poll((CURLM *)THIS(m_http), NULL, 0, timeout, &nfds);
        if(r != CURLM_OK)
            XSRETURN_IV(r);
        if(numfds != NULL){
            sv_setiv(numfds, nfds);
        }
        XSRETURN_IV(r);
#else
        croak("curl_multi_poll is not supported in this version of libcurl");
#endif

void L_curl_multi_wait(SV *m_http=NULL, SV *extrafds=NULL, int timeout=0, SV *numfds=NULL)
    PREINIT:
        int r = 0;
        int nfds = 0;
    PPCODE:
        dTHX;
        dSP;
        if(!THISSvOK(m_http))
            XSRETURN_UNDEF;
        //printf("WAIT: %p, T: %d\n", (CURLM *)THIS(m_http), timeout);
        r = curl_multi_wait((CURLM *)THIS(m_http), NULL, 0, timeout, &nfds);
        if(r != CURLM_OK)
            XSRETURN_IV(r);
        if(numfds != NULL){
            sv_setiv(numfds, nfds);
        }
        XSRETURN_IV(r);

void L_curl_multi_get_handles(SV *m_http=NULL)
    PPCODE:
        dTHX;
#if (LIBCURL_VERSION_NUM >= 0x080400)
        dSP;
        if(!THISSvOK(m_http))
            XSRETURN_UNDEF;
        POPs;
        CURL **e = curl_multi_get_handles((CURLM *)THIS(m_http));
        if(!e)
            XSRETURN_UNDEF;
        AV *av = (AV*)sv_2mortal((SV*)newAV());
        for(int i=0; e[i]; i++){
            void *p = NULL;
            int r = curl_easy_getinfo(e[i], CURLINFO_PRIVATE, &p);
            if(r != CURLE_OK || !p || !((p_curl_easy *)p)->curle)
                continue;
            av_push(av, ((p_curl_easy *)p)->curle);
        }
        curl_free(e);
        XPUSHs(newRV_noinc((SV *)av));
#else
        croak("curl_multi_get_handles is not supported in this version of libcurl");
#endif


MODULE = utils::curl                PACKAGE = http::curl::multi             PREFIX = M_

VERSIONCHECK: DISABLE
PROTOTYPES: DISABLE

void M_DESTROY(SV *m_http=NULL)
    PPCODE:
        dTHX;
        dSP;
        if(!THISSvOK(m_http))
            XSRETURN_UNDEF;
        //printf("destroy_multi: %p\n", (CURLM *)THIS(m_http));
        // get all handles and remove them
#if (LIBCURL_VERSION_NUM >= 0x080400)
        //printf("destroy_multi_handles: %p\n", SvRV(m_http));
        CURL **e = curl_multi_get_handles((CURLM *)THIS(m_http));
        if(e){
            for(int i=0; e[i]; i++){
                curl_multi_remove_handle((CURLM *)THIS(m_http), (CURL *)e[i]);
                void *p = NULL;
                int r = curl_easy_getinfo((CURL *)e[i], CURLINFO_PRIVATE, &p);
                if(r == CURLE_OK && p && ((p_curl_easy *)p)->curle){
                    SvREFCNT_dec((SV *)((p_curl_easy *)p)->curle);
                }
            }
        }
#endif
        int r = curl_multi_cleanup((CURLM *)THIS(m_http));
        if(r != CURLM_OK){
            warn("curl_multi_cleanup failed: %s, 0x%p", curl_multi_strerror(r), (CURLM *)THIS(m_http));
            XSRETURN_NO;
        }
        //printf("after_destroy_curl_multi: %p\n", (CURLM *)THIS(m_http));
        XSRETURN_YES;

MODULE = utils::curl                PACKAGE = http::curl::easy             PREFIX = E_

VERSIONCHECK: DISABLE
PROTOTYPES: DISABLE

void E_DESTROY(SV *e_http=NULL)
    PPCODE:
        dTHX;
        dSP;
        if(!THISSvOK(e_http))
            XSRETURN_UNDEF;
        //printf("destroy_easy: %p\n", (CURL *)THIS(e_http));
        void *p = NULL;
        int r = curl_easy_getinfo((CURL *)THIS(e_http), CURLINFO_PRIVATE, &p);
        if(r == CURLE_OK && p){
            //printf("destroy_easy_cbs: %p, %p\n", (CURL *)THIS(e_http), p);
            ((p_curl_easy *)p)->curle = NULL; // we're about to free ourself (DESTROY SV)
            for(int f=CB_FIRST; f<CB_LAST; f++){
                if(((p_curl_easy *)p)->cb[f]){
                    SvREFCNT_dec((SV *)((p_curl_easy *)p)->cb[f]);
                }
            }
            Safefree(p);
        }
        curl_easy_cleanup((CURL *)THIS(e_http));
        XSRETURN_YES;

MODULE = utils::curl                PACKAGE = http             PREFIX = R_

VERSIONCHECK: DISABLE
PROTOTYPES: DISABLE

#include <sys/time.h>
#include <sys/resource.h>

HV *
R_getrusage (...)
    CODE:
        dTHX;
        dSP;
        HV *rh;

        struct rusage ru_posix = {};
        int r = getrusage(RUSAGE_SELF, &ru_posix);
        if(r == -1){
            SETERRNO(errno, 0);
            XSRETURN_UNDEF;
        }

        rh = (HV *)sv_2mortal((SV *)newHV());

        hv_store(rh , "ru_inblock" , 10 , newSVuv(ru_posix.ru_inblock) , 0);
        hv_store(rh , "ru_oublock" , 10 , newSVuv(ru_posix.ru_oublock) , 0);
        hv_store(rh , "ru_maxrss"  ,  9 , newSVuv(ru_posix.ru_maxrss)  , 0);
        hv_store(rh , "ru_minflt"  ,  9 , newSVuv(ru_posix.ru_minflt)  , 0);
        hv_store(rh , "ru_majflt"  ,  9 , newSVuv(ru_posix.ru_majflt)  , 0);
        hv_store(rh , "ru_nvcsw"   ,  8 , newSVuv(ru_posix.ru_nvcsw)   , 0);
        hv_store(rh , "ru_nivcsw"  ,  9 , newSVuv(ru_posix.ru_nivcsw)  , 0);
        hv_store(rh , "ru_utime"   ,  8 , newSVnv((double)ru_posix.ru_utime.tv_sec + ((double)ru_posix.ru_utime.tv_usec)/1e6) , 0);
        hv_store(rh , "ru_stime"   ,  8 , newSVnv((double)ru_posix.ru_stime.tv_sec + ((double)ru_posix.ru_stime.tv_usec)/1e6) , 0);

        RETVAL = rh;
    OUTPUT:
        RETVAL

MODULE = utils::curl                PACKAGE = http             PREFIX = U_

VERSIONCHECK: DISABLE
PROTOTYPES: DISABLE

void U_curl_url()
    PPCODE:
        dTHX;
        dSP;
        CURLU *u = curl_url();
        if(!u)
            XSRETURN_NO;
        SV *sv = sv_newmortal();
        sv_setref_pv(sv, "http::curl::url", (void *)u);
        SvREADONLY_on(sv);
        XPUSHs(sv);

void U_curl_url_cleanup(SV *u_http=NULL)
    PPCODE:
        dTHX;
        dSP;
        if(!THISSvOK(u_http))
            XSRETURN_UNDEF;
        sv_setref_pv(u_http, NULL, NULL);
        XSRETURN_YES;

void U_curl_url_dup(SV *u_http=NULL)
    PPCODE:
        dTHX;
        dSP;
        if(!THISSvOK(u_http))
            XSRETURN_UNDEF;
        CURLU *u = curl_url_dup((CURLU *)THIS(u_http));
        if(!u)
            XSRETURN_NO;
        SV *sv = sv_newmortal();
        sv_setref_pv(sv, "http::curl::url", (void *)u);
        SvREADONLY_on(sv);
        XPUSHs(sv);

void U_curl_url_get(SV *u_http=NULL, int c_info=0, SV *value=NULL, int flags=0)
    PREINIT:
        char *s = NULL;
    PPCODE:
        dTHX;
        dSP;
        if(!THISSvOK(u_http))
            XSRETURN_UNDEF;
        int r = curl_url_get((CURLU *)THIS(u_http), c_info, &s, flags);
        if(r != CURLUE_OK)
            XSRETURN_IV(r);
        if(value != NULL){
            sv_setpvn(value, s, strlen(s));
        }
        XSRETURN_IV(r);

void U_curl_url_set(SV *u_http=NULL, int c_info=0, SV *value=NULL, int flags=0)
    PPCODE:
        dTHX;
        dSP;
        if(!THISSvOK(u_http))
            XSRETURN_UNDEF;
        if(!value || !SvPOK(value))
            XSRETURN_UNDEF;
        int r = curl_url_set((CURLU *)THIS(u_http), c_info, SvPV_nolen(value), flags);
        if(r != CURLUE_OK)
            XSRETURN_IV(r);
        XSRETURN_IV(r);

void U_curl_url_strerror(int code)
    PPCODE:
        dTHX;
        dSP;
        const char *s = curl_url_strerror(code);
        if(!s)
            XSRETURN_UNDEF;
        XPUSHs(sv_2mortal(newSVpv(s, 0)));

MODULE = utils::curl                PACKAGE = http::curl::url             PREFIX = U_

VERSIONCHECK: DISABLE
PROTOTYPES: DISABLE

void U_DESTROY(SV *u_http=NULL)
    PPCODE:
        dTHX;
        dSP;
        if(!THISSvOK(u_http))
            XSRETURN_UNDEF;
        curl_url_cleanup((CURLU *)THIS(u_http));
        XSRETURN_YES;

MODULE = utils::curl                PACKAGE = http             PREFIX = W_

VERSIONCHECK: DISABLE
PROTOTYPES: DISABLE

void W_curl_ws_meta(SV *ws_http=NULL, SV *key=NULL, SV *value=NULL)
    PPCODE:
        dTHX;
        dSP;
        if(!THISSvOK(ws_http))
            XSRETURN_UNDEF;
        if(!key || !SvPOK(key))
            XSRETURN_UNDEF;
        if(!value || !SvPOK(value))
            XSRETURN_UNDEF;
        const struct curl_ws_frame *w = curl_ws_meta((CURL *)THIS(ws_http));
        if(!w)
            XSRETURN_UNDEF;
        HV *rh = (HV*)sv_2mortal((SV*)newHV());
        hv_store(rh, "age"      ,3,newSViv(w->age)       ,0);
        hv_store(rh, "flags"    ,5,newSViv(w->flags)     ,0);
        hv_store(rh, "offset"   ,6,newSViv(w->offset)    ,0);
        hv_store(rh, "bytesleft",9,newSViv(w->bytesleft) ,0);
        XPUSHs(newRV((SV*)rh));

void W_curl_ws_recv(SV *ws_http=NULL, SV *data=&PL_sv_undef, IV max_sz=0, SV *hv_meta=NULL)
    PREINIT:
        int r = 0;
        size_t recv_sz = 0;
    PPCODE:
        dTHX;
        dSP;
        if(!THISSvOK(ws_http))
            XSRETURN_UNDEF;
        if(!data || !SvPOK(data) || data == &PL_sv_undef)
            XSRETURN_UNDEF;
        if(max_sz == 0)
            XSRETURN_IV(0);
        const struct curl_ws_frame *w = NULL;
        SV *buf = newSV(max_sz);
        SvPOK_only(buf);
        r = curl_ws_recv((CURL *)THIS(ws_http), SvPV_nolen(buf), max_sz, &recv_sz, &w);
        if(r != CURLE_OK)
            XSRETURN_IV(r);
        buf = sv_2mortal(buf);
        SvCUR_set(buf, recv_sz);
        sv_catsv_nomg(data, buf);
        HV *rh = (HV*)sv_2mortal((SV*)newHV());
        hv_store(rh, "age"      ,3,newSViv(w->age)       ,0);
        hv_store(rh, "flags"    ,5,newSViv(w->flags)     ,0);
        hv_store(rh, "offset"   ,6,newSViv(w->offset)    ,0);
        hv_store(rh, "bytesleft",9,newSViv(w->bytesleft) ,0);
        SvRV_set(hv_meta, newRV((SV*)rh));
        XSRETURN_IV(r);

void W_curl_ws_send(SV *ws_http=NULL, SV *data=&PL_sv_undef, int ws_code=0)
    PREINIT:
        int r = 0;
        size_t sent_sz = 0;
    PPCODE:
        dTHX;
        dSP;
        if(!THISSvOK(ws_http))
            XSRETURN_UNDEF;
        if(!data || !SvPOK(data))
            XSRETURN_UNDEF;
        r = curl_ws_send((CURL *)THIS(ws_http), SvPV_nolen(data), SvCUR(data), &sent_sz, 0, ws_code);
        if(r != CURLE_OK)
            XSRETURN_IV(r);
        XSRETURN_IV(0);
