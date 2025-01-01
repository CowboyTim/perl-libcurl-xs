#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#define PERLIO_NOT_STDIO 0    /* For co-existence with stdio only */
#include <perlio.h>           /* Usually via #include <perl.h> */

#include <curl/curl.h>
#include <curl/easy.h>
#include <curl/multi.h>

#define THISSvOK(sv) (sv != NULL && SvROK(sv) && SvOK(SvRV(sv)) && INT2PTR(void *, SvIV(SvRV(sv))) != NULL)
#define THIS(sv)   INT2PTR(void *, SvIV(SvRV(sv)))

#define MAX_CB 17

enum perl_cb_function {
    CB_DEBUGFUNCTION = 0,
    CB_CLOSESOCKETFUNCTION,
    CB_OPENSOCKETFUNCTION,
    CB_HEADERFUNCTION,
    CB_HSTSREADFUNCTION,
    CB_HSTSWRITEFUNCTION,
    CB_IOCTLFUNCTION,
    CB_PREREQFUNCTION,
    CB_PROGRESSFUNCTION,
    CB_READFUNCTION,
    CB_WRITEFUNCTION,
    CB_RESOLVER_START_FUNCTION,
    CB_SEEKFUNCTION,
    CB_SOCKOPTFUNCTION,
    CB_SSL_CTX_FUNCTION,
    CB_TRAILERFUNCTION,
    CB_XFERINFOFUNCTION
};

typedef struct p_c_fn {
    int f;
    int d;
    void *fn;
} p_c_fn;

typedef struct {
    SV *cb;
    SV *cd;
} p_curl_cb;

typedef struct {
    SV *curle;
    p_curl_cb cbs[MAX_CB];
    SV *private;
    SV *postfields;
    SV *curlu;
    SV *errbuffer;
    SV *fd_stderr_sv;
    struct curl_slist *headers_slist;
} p_curl_easy;

static int curl_debugfunction_cb(CURL *handle, curl_infotype type, char *data, size_t size, void *userp){
    dTHX;
    dSP;
    //printf("curl_debugfunction_cb 1 %p %d %s %p\n", handle, type, data,  userp);
    if(!userp)
        return 0;
    //printf("curl_debugfunction_cb 2 %p %p\n", handle,   userp);
    p_curl_easy *pe = (p_curl_easy *)userp;
    SV *cd = (SV *)(pe->cbs[CB_DEBUGFUNCTION].cd);
    SV *cb = (SV *)(pe->cbs[CB_DEBUGFUNCTION].cb);
    //printf("curl_debugfunction_cb 3 %p %p %p %p\n", handle, userp, cb, cd);
    if(!cb || SvTYPE(cb) != SVt_PVCV)
        return 0;
    //printf("curl_debugfunction_cb 4 %p %p %p %p\n", handle, userp, cb, cd);
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    mXPUSHs(newRV_inc(pe->curle));
    mXPUSHs(newSViv((IV)type));
    mXPUSHs(newSVpv(data, size));
    if(cd && SvOK((SV *)cd))
        XPUSHs((SV *)cd);
    else
        XPUSHs(&PL_sv_undef);
    PUTBACK;
    call_sv(cb, G_EVAL|G_DISCARD|G_KEEPERR);
    SPAGAIN;
    SV *err_tmp = ERRSV;
    if(SvTRUE(err_tmp))
        POPs;
    PUTBACK;
    FREETMPS;
    LEAVE;
    return 0;
}

static int curl_closesocketfunction_cb(void *userp, curl_socket_t curlfd){
    dTHX;
    dSP;
    //printf("curl_closesocketfunction_cb\n");
    if(!userp)
        return 0;
    p_curl_easy *pe = (p_curl_easy *)userp;
    SV *cd = (SV *)(pe->cbs[CB_CLOSESOCKETFUNCTION].cd);
    SV *cb = (SV *)(pe->cbs[CB_CLOSESOCKETFUNCTION].cb);
    //printf("curl_closesocketfunction_cb 0 %p %p\n", cb, cd);
    if(!cb || SvTYPE(cb) != SVt_PVCV)
        return 0;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    PerlIO *f= PerlIO_openn(aTHX_ ":unix", "r+b", curlfd, 0, 0, NULL, 0, NULL);
    if(!f){
        SETERRNO(0, 0);
    }
    Perl_PerlIO_save_errno(aTHX_ f);
    GV *gv = newGVgen("http::curl::easy");
    IoIFP(GvIOn(gv)) = f;
    IoOFP(GvIOn(gv)) = f;
    IoTYPE(GvIOn(gv))= IoTYPE_NUMERIC;
    SV *fh = sv_newmortal();
    sv_setsv(fh, newRV_noinc((SV *)gv));
    SvSETMAGIC(fh);
    SETERRNO(0, 0);
    XPUSHs(fh);
    if(cd && SvOK(cd))
        XPUSHs(cd);
    else
        XPUSHs(&PL_sv_undef);
    PUTBACK;
    //printf("curl_closesocketfunction_cb 1\n");
    int r = call_sv(cb, G_EVAL|G_SCALAR|G_KEEPERR);
    SPAGAIN;
    int res = 0;
    SV *err_tmp = ERRSV;
    if(SvTRUE(err_tmp)){
        POPs;
    } else {
        if(r >= 1)
            res = POPi;
    }
    PUTBACK;
    FREETMPS;
    LEAVE;
    return res;
}

static int curl_opensocketfunction_cb(void *userp, curlsocktype purpose, struct curl_sockaddr *address){
    dTHX;
    dSP;
    //printf("curl_opensocketfunction_cb\n");
    if(!userp)
        return CURL_SOCKET_BAD;
    //printf("curl_opensocketfunction_cb 11 %p\n", userp);
    p_curl_easy *pe = (p_curl_easy *)userp;
    SV *cd = (SV *)(pe->cbs[CB_OPENSOCKETFUNCTION].cd);
    //printf("curl_opensocketfunction_cb 12\n");
    SV *cb = (SV *)(pe->cbs[CB_OPENSOCKETFUNCTION].cb);
    //printf("curl_opensocketfunction_cb 13 %p\n", cb);
    if(!cb || SvTYPE(cb) != SVt_PVCV)
        return CURL_SOCKET_BAD;
    //printf("curl_opensocketfunction_cb 2 %p %p\n", cb, cd);
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    mXPUSHs(newSViv((IV)purpose));
    mXPUSHs(newSViv((IV)address->family));
    mXPUSHs(newSViv((IV)address->socktype));
    mXPUSHs(newSViv((IV)address->protocol));
    // copy for now, but address->addr allows for updates from the callback per curl doc
    mXPUSHs(newSVpv((char *)&address->addr, address->addrlen));
    if(cd && SvOK(cd)){
        XPUSHs(cd);
    } else {
        XPUSHs(&PL_sv_undef);
    }
    PUTBACK;
    int r = call_sv(cb, G_EVAL|G_SCALAR|G_KEEPERR);
    SPAGAIN;
    SV *err_tmp = ERRSV;
    if(SvTRUE(err_tmp)){
        POPs;
        PUTBACK;
        FREETMPS;
        LEAVE;
        return CURL_SOCKET_BAD;
    }
    SV *res = NULL;
    if(r == 1){
        res = POPs;
    } else {
        PUTBACK;
        FREETMPS;
        LEAVE;
        return CURL_SOCKET_BAD;
    }
    //printf("curl_opensocketfunction_cb 7 %p %d %d\n", res, SvOK(res), SvTYPE(res));
    if(!res || !SvOK(res)){
        PUTBACK;
        FREETMPS;
        LEAVE;
        return CURL_SOCKET_BAD;
    }
    if(looks_like_number(res)){
        int fd = (int)SvIV(res);
        //printf("curl_opensocketfunction_cb 8 %d\n", (int)SvIV(res));
        PUTBACK;
        FREETMPS;
        LEAVE;
        return fd;
    }
    SV *rf = SvRV(res);
    //printf("curl_opensocketfunction_cb OK? %p %d %d\n", res, SvOK(rf), SvTYPE(rf));
    if(SvTYPE(rf) != SVt_PVGV){
        //printf("curl_opensocketfunction_cb GV %p %d %d\n", res, SvOK(rf), SvTYPE(rf));
        PUTBACK;
        FREETMPS;
        LEAVE;
        return CURL_SOCKET_BAD;
    }
    GV *gv = (GV *)rf;
    if(!GvIO(gv)){
        //printf("curl_opensocketfunction_cb IO %p %d %d\n", res, SvOK(rf), SvTYPE(rf));
        PUTBACK;
        FREETMPS;
        LEAVE;
        return CURL_SOCKET_BAD;
    }
    int fd = PerlIO_fileno(IoIFP(GvIOn(gv)));
    //printf("curl_opensocketfunction_cb 4 %d\n", fd);
    if(fd < 0){
        PUTBACK;
        FREETMPS;
        LEAVE;
        return CURL_SOCKET_BAD;
    }
    PUTBACK;
    FREETMPS;
    LEAVE;
    return fd;
}

static int curl_headerfunction_cb(char *data, size_t size, size_t nmemb, void *userp){
    dTHX;
    dSP;
    if(!userp)
        return 0;
    p_curl_easy *pe = (p_curl_easy *)userp;
    SV *cd = (SV *)(pe->cbs[CB_HEADERFUNCTION].cd);
    SV *cb = (SV *)(pe->cbs[CB_HEADERFUNCTION].cb);
    if(!cb || SvTYPE(cb) != SVt_PVCV)
        return 0;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    mXPUSHs(newSVpv(data, size*nmemb));
    if(cd && SvOK(cd))
        XPUSHs(cd);
    else
        XPUSHs(&PL_sv_undef);
    PUTBACK;
    int r = call_sv(cb, G_EVAL|G_SCALAR|G_KEEPERR);
    SPAGAIN;
    int res = 0;
    SV *err_tmp = ERRSV;
    if(SvTRUE(err_tmp)){
        POPs;
    } else {
        if(r >= 1)
            res = POPi;
    }
    PUTBACK;
    FREETMPS;
    LEAVE;
    return res;
}

static int curl_hstsreadfunction_cb(char *buffer, size_t size, size_t nitems, void *userp){
    dTHX;
    dSP;
    if(!userp)
        return 0;
    p_curl_easy *pe = (p_curl_easy *)userp;
    SV *cd = (SV *)(pe->cbs[CB_HSTSREADFUNCTION].cd);
    SV *cb = (SV *)(pe->cbs[CB_HSTSREADFUNCTION].cb);
    if(!cb || SvTYPE(cb) != SVt_PVCV)
        return 0;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    mXPUSHs(newSVpv(buffer, size*nitems));
    if(cd && SvOK(cd))
        XPUSHs(cd);
    else
        XPUSHs(&PL_sv_undef);
    PUTBACK;
    call_sv(cb, G_EVAL|G_DISCARD|G_KEEPERR);
    SPAGAIN;
    SV *err_tmp = ERRSV;
    if(SvTRUE(err_tmp))
        POPs;
    PUTBACK;
    FREETMPS;
    LEAVE;
    return 0;
}

static int curl_hstswritefunction_cb(char *buffer, size_t size, size_t nitems, void *userp){
    dTHX;
    dSP;
    if(!userp)
        return 0;
    p_curl_easy *pe = (p_curl_easy *)userp;
    SV *cd = (SV *)(pe->cbs[CB_HSTSWRITEFUNCTION].cd);
    SV *cb = (SV *)(pe->cbs[CB_HSTSWRITEFUNCTION].cb);
    if(!cb || SvTYPE(cb) != SVt_PVCV)
        return 0;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    mXPUSHs(newSVpv(buffer, size*nitems));
    if(cd && SvOK(cd))
        XPUSHs(cd);
    else
        XPUSHs(&PL_sv_undef);
    PUTBACK;
    call_sv(cb, G_EVAL|G_DISCARD|G_KEEPERR);
    SPAGAIN;
    SV *err_tmp = ERRSV;
    if(SvTRUE(err_tmp))
        POPs;
    PUTBACK;
    FREETMPS;
    LEAVE;
    return 0;
}

static int curl_ioctlfunction_cb(CURL *handle, int cmd, void *userp){
    dTHX;
    dSP;
    if(!userp)
        return 0;
    p_curl_easy *pe = (p_curl_easy *)userp;
    SV *cd = (SV *)(pe->cbs[CB_IOCTLFUNCTION].cd);
    SV *cb = (SV *)(pe->cbs[CB_IOCTLFUNCTION].cb);
    if(!cb || SvTYPE(cb) != SVt_PVCV)
        return 0;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    mXPUSHs(newRV_inc(pe->curle));
    mXPUSHs(newSViv(cmd));
    if(cd && SvOK((SV *)cd))
        XPUSHs((SV *)cd);
    else
        XPUSHs(&PL_sv_undef);
    PUTBACK;
    int r = call_sv(cb, G_EVAL|G_SCALAR|G_KEEPERR);
    SPAGAIN;
    int res = 0;
    SV *err_tmp = ERRSV;
    if(SvTRUE(err_tmp)){
        POPs;
    } else {
        if(r >= 1)
            res = POPi;
    }
    PUTBACK;
    FREETMPS;
    LEAVE;
    return res;
}

static int curl_prereqfunction_cb(void *userp, char *conn_primary_ip, char *conn_local_ip, int conn_primary_port, int conn_local_port){
    dTHX;
    dSP;
    if(!userp)
        return 0;
    p_curl_easy *pe = (p_curl_easy *)userp;
    SV *cd = (SV *)(pe->cbs[CB_PREREQFUNCTION].cd);
    SV *cb = (SV *)(pe->cbs[CB_PREREQFUNCTION].cb);
    if(!cb || SvTYPE(cb) != SVt_PVCV)
        return 0;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    mXPUSHs(newSVpv(conn_primary_ip, 0));
    mXPUSHs(newSVpv(conn_local_ip, 0));
    mXPUSHs(newSViv(conn_primary_port));
    mXPUSHs(newSViv(conn_local_port));
    if(cd && SvOK(cd))
        XPUSHs(cd);
    else
        XPUSHs(&PL_sv_undef);
    PUTBACK;
    int r = call_sv(cb, G_EVAL|G_SCALAR|G_KEEPERR);
    SPAGAIN;
    int res = 0;
    SV *err_tmp = ERRSV;
    if(SvTRUE(err_tmp)){
        POPs;
    } else {
        if(r >= 1)
            res = POPi;
    }
    PUTBACK;
    FREETMPS;
    LEAVE;
    return res;
}

static int curl_progressfunction_cb(void *userp, double dltotal, double dlnow, double ultotal, double ulnow){
    dTHX;
    dSP;
    if(!userp)
        return 0;
    p_curl_easy *pe = (p_curl_easy *)userp;
    SV *cd = (SV *)(pe->cbs[CB_PROGRESSFUNCTION].cd);
    SV *cb = (SV *)(pe->cbs[CB_PROGRESSFUNCTION].cb);
    if(!cb || SvTYPE(cb) != SVt_PVCV)
        return 0;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    mXPUSHs(newSVnv(dltotal));
    mXPUSHs(newSVnv(dlnow));
    mXPUSHs(newSVnv(ultotal));
    mXPUSHs(newSVnv(ulnow));
    if(cd && SvOK(cd))
        XPUSHs(cd);
    else
        XPUSHs(&PL_sv_undef);
    PUTBACK;
    int r = call_sv(cb, G_EVAL|G_SCALAR|G_KEEPERR);
    SPAGAIN;
    int res = 0;
    SV *err_tmp = ERRSV;
    if(SvTRUE(err_tmp)){
        POPs;
    } else {
        if(r >= 1)
            res = POPi;
    }
    PUTBACK;
    FREETMPS;
    LEAVE;
    return res;
}

static int curl_readfunction_cb(void *buffer, size_t size, size_t nitems, void *userp){
    dTHX;
    dSP;
    if(!userp)
        return 0;
    p_curl_easy *pe = (p_curl_easy *)userp;
    SV *cd = (SV *)(pe->cbs[CB_READFUNCTION].cd);
    SV *cb = (SV *)(pe->cbs[CB_READFUNCTION].cb);
    if(!cb || SvTYPE(cb) != SVt_PVCV)
        return 0;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    mXPUSHs(newRV_inc(pe->curle));
    mXPUSHs(newSViv(size*nitems));
    if(cd && SvOK(cd))
        XPUSHs(cd);
    else
        XPUSHs(&PL_sv_undef);
    PUTBACK;
    int r = call_sv(cb, G_EVAL|G_SCALAR|G_KEEPERR);
    SPAGAIN;
    SV *err_tmp = ERRSV;
    if(SvTRUE(err_tmp)){
        POPs;
        PUTBACK;
        FREETMPS;
        LEAVE;
        return 0;
    }
    if(!r){
        PUTBACK;
        FREETMPS;
        LEAVE;
        return 0;
    }
    SV *sv = POPs;
    if(!SvPOK(sv)){
        PUTBACK;
        FREETMPS;
        LEAVE;
        return 0;
    }
    size_t len = SvCUR(sv);
    if(len){
        if(len > size*nitems)
            len = size*nitems;
        memcpy(buffer, SvPV_nolen(sv), len);
    }
    PUTBACK;
    FREETMPS;
    LEAVE;
    return len;
}

static int curl_writefunction_cb(void *buffer, size_t size, size_t nitems, void *userp){
    dTHX;
    dSP;
    if(!userp)
        return 0;
    p_curl_easy *pe = (p_curl_easy *)userp;
    SV *cd = (SV *)(pe->cbs[CB_WRITEFUNCTION].cd);
    SV *cb = (SV *)(pe->cbs[CB_WRITEFUNCTION].cb);
    if(!cb || SvTYPE(cb) != SVt_PVCV)
        return 0;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    mXPUSHs(newRV_inc(pe->curle));
    mXPUSHs(newSVpv(buffer, size*nitems));
    if(cd && SvOK(cd))
        XPUSHs(cd);
    else
        XPUSHs(&PL_sv_undef);
    PUTBACK;
    int r = call_sv(cb, G_EVAL|G_SCALAR|G_KEEPERR);
    SPAGAIN;
    int res = 0;
    if(r >= 1)
        res = POPi;
    SV *err_tmp = ERRSV;
    if(SvTRUE(err_tmp))
        POPs;
    PUTBACK;
    FREETMPS;
    LEAVE;
    return res;
}

static int curl_resolver_start_function_cb(void *resolver_state, void *reserved, void *userp){
    dTHX;
    dSP;
    if(!userp)
        return 0;
    p_curl_easy *pe = (p_curl_easy *)userp;
    SV *cd = (SV *)(pe->cbs[CB_RESOLVER_START_FUNCTION].cd);
    SV *cb = (SV *)(pe->cbs[CB_RESOLVER_START_FUNCTION].cb);
    if(!cb || SvTYPE(cb) != SVt_PVCV)
        return 0;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    mXPUSHs(newSViv(PTR2IV(resolver_state)));
    if(cd && SvOK(cd))
        XPUSHs(cd);
    else
        XPUSHs(&PL_sv_undef);
    PUTBACK;
    int r = call_sv(cb, G_EVAL|G_SCALAR|G_KEEPERR);
    SPAGAIN;
    int res = 0;
    SV *err_tmp = ERRSV;
    if(SvTRUE(err_tmp)){
        POPs;
    } else {
        if(r >= 1)
            res = POPi;
    }
    PUTBACK;
    FREETMPS;
    LEAVE;
    return res;
}

static int curl_seekfunction_cb(void *userp, curl_off_t offset, int origin){
    dTHX;
    dSP;
    if(!userp)
        return 0;
    p_curl_easy *pe = (p_curl_easy *)userp;
    SV *cd = (SV *)(pe->cbs[CB_SEEKFUNCTION].cd);
    SV *cb = (SV *)(pe->cbs[CB_SEEKFUNCTION].cb);
    if(!cb || SvTYPE(cb) != SVt_PVCV)
        return 0;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    mXPUSHs(newSViv((IV)offset));
    mXPUSHs(newSViv((IV)origin));
    if(cd && SvOK(cd))
        XPUSHs(cd);
    else
        XPUSHs(&PL_sv_undef);
    PUTBACK;
    int r = call_sv(cb, G_EVAL|G_SCALAR|G_KEEPERR);
    SPAGAIN;
    int res = 0;
    SV *err_tmp = ERRSV;
    if(SvTRUE(err_tmp)){
        POPs;
    } else {
        if(r >= 1)
            res = POPi;
    }
    PUTBACK;
    FREETMPS;
    LEAVE;
    return res;
}

static int curl_sockoptfunction_cb(void *userp, curl_socket_t curlfd, curlsocktype purpose){
    dTHX;
    dSP;
    if(!userp)
        return 0;
    p_curl_easy *pe = (p_curl_easy *)userp;
    SV *cd = (SV *)(pe->cbs[CB_SOCKOPTFUNCTION].cd);
    SV *cb = (SV *)(pe->cbs[CB_SOCKOPTFUNCTION].cb);
    if(!cb || SvTYPE(cb) != SVt_PVCV)
        return 0;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    PerlIO *f= PerlIO_openn(aTHX_ ":unix", "r+b", curlfd, 0, 0, NULL, 0, NULL);
    if(!f){
        SETERRNO(0, 0);
    }
    Perl_PerlIO_save_errno(aTHX_ f);
    GV *gv = newGVgen("http::curl::easy");
    IoIFP(GvIOn(gv)) = f;
    IoOFP(GvIOn(gv)) = f;
    IoTYPE(GvIOn(gv))= IoTYPE_NUMERIC;
    SV *fh = sv_newmortal();
    sv_setsv(fh, newRV_noinc((SV *)gv));
    SvSETMAGIC(fh);
    SETERRNO(0, 0);
    XPUSHs(fh);
    mXPUSHs(newSViv(PTR2IV(purpose)));
    if(cd && SvOK(cd))
        XPUSHs(cd);
    else
        XPUSHs(&PL_sv_undef);
    PUTBACK;
    int r = call_sv(cb, G_EVAL|G_SCALAR|G_KEEPERR);
    SPAGAIN;
    int res = 0;
    SV *err_tmp = ERRSV;
    if(SvTRUE(err_tmp)){
        POPs;
    } else {
        if(r >= 1)
            res = POPi;
    }
    PUTBACK;
    FREETMPS;
    LEAVE;
    return res;
}

static int curl_ssl_ctx_function_cb(CURL *handle, void *sslctx, void *userp){
    dTHX;
    dSP;
    //printf("curl_ssl_ctx_function_cb 1 %p %p %p\n", handle, sslctx, userp);
    if(!userp)
        return 0;
    p_curl_easy *pe = (p_curl_easy *)userp;
    //printf("curl_ssl_ctx_function_cb 2 %p %p %p\n", handle, sslctx, pe);
    SV *cd = (SV *)(pe->cbs[CB_SSL_CTX_FUNCTION].cd);
    SV *cb = (SV *)(pe->cbs[CB_SSL_CTX_FUNCTION].cb);
    //printf("curl_ssl_ctx_function_cb 3 %p %p %p %p\n", handle, sslctx, cb, cd);
    if(!cb || SvTYPE(cb) != SVt_PVCV)
        return 0;
    //printf("curl_ssl_ctx_function_cb 4 %p %p %p\n", handle, sslctx, cd);
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    mXPUSHs(newRV_inc(pe->curle));
    mXPUSHs(newSViv(PTR2IV(sslctx)));
    if(cd && SvOK((SV *)cd))
        XPUSHs((SV *)cd);
    else
        XPUSHs(&PL_sv_undef);
    PUTBACK;
    int r = call_sv(cb, G_EVAL|G_SCALAR|G_KEEPERR);
    SPAGAIN;
    int res = 0;
    SV *err_tmp = ERRSV;
    if(SvTRUE(err_tmp)){
        POPs;
    } else {
        if(r >= 1)
            res = POPi;
    }
    PUTBACK;
    FREETMPS;
    LEAVE;
    //printf("curl_ssl_ctx_function_cb 3\n");
    return res;
}

static int curl_trailerfunction_cb(char *data, size_t size, size_t nmemb, void *userp){
    dTHX;
    dSP;
    if(!userp)
        return 0;
    p_curl_easy *pe = (p_curl_easy *)userp;
    SV *cd = (SV *)(pe->cbs[CB_TRAILERFUNCTION].cd);
    SV *cb = (SV *)(pe->cbs[CB_TRAILERFUNCTION].cb);
    if(!cb || SvTYPE(cb) != SVt_PVCV)
        return 0;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    mXPUSHs(newSVpv(data, size*nmemb));
    if(cd && SvOK(cd))
        XPUSHs(cd);
    else
        XPUSHs(&PL_sv_undef);
    PUTBACK;
    call_sv(cb, G_EVAL|G_DISCARD|G_KEEPERR);
    SPAGAIN;
    SV *err_tmp = ERRSV;
    if(SvTRUE(err_tmp))
        POPs;
    PUTBACK;
    FREETMPS;
    LEAVE;
    return 0;
}

static int curl_xferinfofunction_cb(void *userp, curl_off_t dltotal, curl_off_t dlnow, curl_off_t ultotal, curl_off_t ulnow){
    dTHX;
    dSP;
    if(!userp)
        return 0;
    p_curl_easy *pe = (p_curl_easy *)userp;
    SV *cd = (SV *)(pe->cbs[CB_XFERINFOFUNCTION].cd);
    SV *cb = (SV *)(pe->cbs[CB_XFERINFOFUNCTION].cb);
    if(!cb || SvTYPE(cb) != SVt_PVCV)
        return 0;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    mXPUSHs(newSViv((IV)dltotal));
    mXPUSHs(newSViv((IV)dlnow));
    mXPUSHs(newSViv((IV)ultotal));
    mXPUSHs(newSViv((IV)ulnow));
    if(cd && SvOK(cd))
        XPUSHs(cd);
    else
        XPUSHs(&PL_sv_undef);
    PUTBACK;
    int r = call_sv(cb, G_EVAL|G_SCALAR|G_KEEPERR);
    SPAGAIN;
    int res = 0;
    SV *err_tmp = ERRSV;
    if(SvTRUE(err_tmp)){
        POPs;
    } else {
        if(r >= 1)
            res = POPi;
    }
    PUTBACK;
    FREETMPS;
    LEAVE;
    return res;
}

static const p_c_fn curl_cb_opts[] = {
    [CB_DEBUGFUNCTION] = {
        .f=CURLOPT_DEBUGFUNCTION,
        .d=CURLOPT_DEBUGDATA,
        .fn = curl_debugfunction_cb
    },
    [CB_CLOSESOCKETFUNCTION] = {
        .f=CURLOPT_CLOSESOCKETFUNCTION,
        .d=CURLOPT_CLOSESOCKETDATA,
        .fn = curl_closesocketfunction_cb
    },
    [CB_OPENSOCKETFUNCTION] = {
        .f=CURLOPT_OPENSOCKETFUNCTION,
        .d=CURLOPT_OPENSOCKETDATA,
        .fn = curl_opensocketfunction_cb
    },
    [CB_HEADERFUNCTION] = {
        .f=CURLOPT_HEADERFUNCTION,
        .d=CURLOPT_HEADERDATA,
        .fn = curl_headerfunction_cb
    },
    [CB_HSTSREADFUNCTION] = {
        .f=CURLOPT_HSTSREADFUNCTION,
        .d=CURLOPT_HSTSREADDATA,
        .fn = curl_hstsreadfunction_cb
    },
    [CB_HSTSWRITEFUNCTION] = {
        .f=CURLOPT_HSTSWRITEFUNCTION,
        .d=CURLOPT_HSTSWRITEDATA,
        .fn = curl_hstswritefunction_cb
    },
    [CB_IOCTLFUNCTION] = {
        .f=CURLOPT_IOCTLFUNCTION,
        .d=CURLOPT_IOCTLDATA,
        .fn = curl_ioctlfunction_cb
    },
    [CB_PREREQFUNCTION] = {
        .f=CURLOPT_PREREQFUNCTION,
        .d=CURLOPT_PREREQDATA,
        .fn = curl_prereqfunction_cb
    },
    [CB_PROGRESSFUNCTION] = {
        .f=CURLOPT_PROGRESSFUNCTION,
        .d=CURLOPT_PROGRESSDATA,
        .fn = curl_progressfunction_cb
    },
    [CB_READFUNCTION] = {
        .f=CURLOPT_READFUNCTION,
        .d=CURLOPT_READDATA,
        .fn = curl_readfunction_cb
    },
    [CB_WRITEFUNCTION] = {
        .f=CURLOPT_WRITEFUNCTION,
        .d=CURLOPT_WRITEDATA,
        .fn = curl_writefunction_cb
    },
    [CB_RESOLVER_START_FUNCTION] = {
        .f=CURLOPT_RESOLVER_START_FUNCTION,
        .d=CURLOPT_RESOLVER_START_DATA,
        .fn = curl_resolver_start_function_cb
    },
    [CB_SEEKFUNCTION] = {
        .f=CURLOPT_SEEKFUNCTION,
        .d=CURLOPT_SEEKDATA,
        .fn = curl_seekfunction_cb
    },
    [CB_SOCKOPTFUNCTION] = {
        .f=CURLOPT_SOCKOPTFUNCTION,
        .d=CURLOPT_SOCKOPTDATA,
        .fn = curl_sockoptfunction_cb
    },
    [CB_SSL_CTX_FUNCTION] = {
        .f=CURLOPT_SSL_CTX_FUNCTION,
        .d=CURLOPT_SSL_CTX_DATA,
        .fn = curl_ssl_ctx_function_cb
    },
    [CB_TRAILERFUNCTION] = {
        .f=CURLOPT_TRAILERFUNCTION,
        .d=CURLOPT_TRAILERDATA,
        .fn = curl_trailerfunction_cb
    },
    [CB_XFERINFOFUNCTION] = {
        .f=CURLOPT_XFERINFOFUNCTION,
        .d=CURLOPT_XFERINFODATA,
        .fn = curl_xferinfofunction_cb
    }
};

int cb_setup_pvt(CURL *e_http, int cb_indx, SV *cb, SV **ret){
    int r = 0, o = 0, t = 0, do_croak = 0;
    void *p = NULL;
    SV **pp_d = NULL;
    int opt_f  = curl_cb_opts[cb_indx].f;
    int opt_d  = curl_cb_opts[cb_indx].d;
    void *cb_f = curl_cb_opts[cb_indx].fn;
    //printf("cb_setup_pvt %d %d %p\n", opt_f, opt_d, cb_f);
    t = curl_easy_getinfo(e_http, CURLINFO_PRIVATE, &p);
    if(t == CURLE_OK){
        if(p == NULL){
            do_croak = 1;
        } else {
            pp_d = &(((p_curl_easy *)p)->cbs[cb_indx].cd);
            *ret = ((p_curl_easy *)p)->cbs[cb_indx].cb;
        }
    }
    if(p == NULL){
        do_croak = 1;
    } else {
        if(cb){
            //printf("cb_setup_pvt set f %d %p %p\n", opt_f, cb, cb_f);
            r = curl_easy_setopt(e_http, opt_f, cb_f);
            if(r == CURLE_OK){
                ((p_curl_easy *)p)->cbs[cb_indx].cb = cb;
                //printf("cb_setup_pvt set p %d %p %p %p cb: %p\n", opt_d, cb, cb_f, p, (((p_curl_easy *)p)->cbs[cb_indx].cb));
                // we set the userp to the vl of private data
                o = curl_easy_setopt(e_http, opt_d, p);
                if(o != CURLE_OK){
                    //printf("cb_setup_pvt err %d\n", o);
                    do_croak = 1;
                }
            } else {
                do_croak = 1;
            }
        } else {
            ((p_curl_easy *)p)->cbs[cb_indx].cb = NULL;
            r = curl_easy_setopt(e_http, opt_f, NULL);
            if(*pp_d == NULL){
                o = curl_easy_setopt(e_http, opt_d, NULL);
                if(o != CURLE_OK)
                    do_croak = 1;
            }
        }
    }
    if(do_croak){
        //printf("cb_setup_pvt croak %d %d\n", r, o);
        ((p_curl_easy *)p)->cbs[cb_indx].cb = NULL;
        o = curl_easy_setopt(e_http, opt_f, NULL);
        if(*pp_d == NULL){
            o = curl_easy_setopt(e_http, opt_d, NULL);
        }
        croak("curl_easy_setopt failed %d %d", r, o);
    }
    return r;
}

int cd_setup_pvt(CURL *e_http, int cb_indx, SV *vl, SV **ret){
    int r = 0;
    void *p = NULL;
    SV **pp_d = NULL;
    SV **pp_c = NULL;
    int opt_d = curl_cb_opts[cb_indx].d;
    int t = curl_easy_getinfo(e_http, CURLINFO_PRIVATE, &p);
    if(t == CURLE_OK && p){
        pp_c = &(((p_curl_easy *)p)->cbs[cb_indx].cb);
        pp_d = &(((p_curl_easy *)p)->cbs[cb_indx].cd);
        *ret = *pp_d;
    }
    if(vl){
        // we set the userp to the vl of private data
        r = curl_easy_setopt(e_http, opt_d, p);
        if(r == CURLE_OK){
            *pp_d = vl;
        } else {
            *pp_d = NULL;
            if(*pp_c == NULL)
                r = curl_easy_setopt(e_http, opt_d, NULL);
        }
    } else {
        // we reset this callback's "cd" in the private struct
        *pp_d = NULL;
        if(*pp_c == NULL)
            r = curl_easy_setopt(e_http, opt_d, NULL);
    }
    return r;
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
        newCONSTSUB(stash, "CURL_PREREQFUNC_OK"         , newSViv(CURL_PREREQFUNC_OK));
        newCONSTSUB(stash, "CURL_PREREQFUNC_ABORT"      , newSViv(CURL_PREREQFUNC_ABORT));
        newCONSTSUB(stash, "CURL_SSLVERSION_DEFAULT"    , newSViv(CURL_SSLVERSION_DEFAULT));
        newCONSTSUB(stash, "CURL_SSLVERSION_TLSv1"      , newSViv(CURL_SSLVERSION_TLSv1));
        newCONSTSUB(stash, "CURL_SSLVERSION_SSLv2"      , newSViv(CURL_SSLVERSION_SSLv2));
        newCONSTSUB(stash, "CURL_SSLVERSION_SSLv3"      , newSViv(CURL_SSLVERSION_SSLv3));
        newCONSTSUB(stash, "CURL_SSLVERSION_TLSv1_0"    , newSViv(CURL_SSLVERSION_TLSv1_0));
        newCONSTSUB(stash, "CURL_SSLVERSION_TLSv1_1"    , newSViv(CURL_SSLVERSION_TLSv1_1));
        newCONSTSUB(stash, "CURL_SSLVERSION_TLSv1_2"    , newSViv(CURL_SSLVERSION_TLSv1_2));
        newCONSTSUB(stash, "CURL_SSLVERSION_TLSv1_3"    , newSViv(CURL_SSLVERSION_TLSv1_3));
        newCONSTSUB(stash, "CURL_SSLVERSION_MAX_DEFAULT", newSViv(CURL_SSLVERSION_MAX_DEFAULT));
        newCONSTSUB(stash, "CURL_SSLVERSION_MAX_TLSv1_0", newSViv(CURL_SSLVERSION_MAX_TLSv1_0));
        newCONSTSUB(stash, "CURL_SSLVERSION_MAX_TLSv1_1", newSViv(CURL_SSLVERSION_MAX_TLSv1_1));
        newCONSTSUB(stash, "CURL_SSLVERSION_MAX_TLSv1_2", newSViv(CURL_SSLVERSION_MAX_TLSv1_2));
        newCONSTSUB(stash, "CURL_SSLVERSION_MAX_TLSv1_3", newSViv(CURL_SSLVERSION_MAX_TLSv1_3));
        newCONSTSUB(stash, "CURL_TIMECOND_NONE"         , newSViv(CURL_TIMECOND_NONE));
        newCONSTSUB(stash, "CURL_TIMECOND_IFMODSINCE"   , newSViv(CURL_TIMECOND_IFMODSINCE));
        newCONSTSUB(stash, "CURL_TIMECOND_IFUNMODSINCE" , newSViv(CURL_TIMECOND_IFUNMODSINCE));
        newCONSTSUB(stash, "CURL_TIMECOND_LASTMOD"      , newSViv(CURL_TIMECOND_LASTMOD));
#if (LIBCURL_VERSION_NUM >= 0x073f00)
        newCONSTSUB(stash, "CURL_PUSH_ERROROUT"         , newSViv(CURL_PUSH_ERROROUT));
#else
        newCONSTSUB(stash, "CURL_PUSH_ERROROUT"         , newSViv(2));
#endif
        int r = curl_global_init(CURL_GLOBAL_DEFAULT);
        if(r != 0)
            croak("curl_global_init failed: %d: %s", r, curl_easy_strerror(r));
}

INCLUDE: ../../curl_constants.xsh

#ifndef CURLOPTTYPE_BLOB
#define CURLOPTTYPE_BLOB 40000
#endif

void L_curl_global_init(...)
    PREINIT:
        int r;
    CODE:
        dTHX;
        dSP;
        if(items == 1){
            if(SvOK(ST(0)) && looks_like_number(ST(0))){
                r = curl_global_init(SvIV(ST(0)));
            } else {
                r = curl_global_init(CURL_GLOBAL_DEFAULT);
            }
        } else {
            r = curl_global_init(CURL_GLOBAL_DEFAULT);
        }
        XSRETURN_IV(r);

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
        rh = newHV();
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
        ST(0) = newRV_inc((SV *)rh);
        sv_2mortal(ST(0));
        XSRETURN(1);

void L_curl_version(...)
    PPCODE:
        dTHX;
        dSP;
        ST(0) = newSVpv(curl_version(), 0);
        sv_2mortal(ST(0));
        XSRETURN(1);

void L_curl_easy_init()
    PPCODE:
        dTHX;
        dSP;
        CURL *c = curl_easy_init();
        if(!c)
            XSRETURN_NO;
        void *ptr = NULL;
        Newxz(ptr, 1, p_curl_easy);
        if(!ptr)
            XSRETURN_IV(CURLE_OUT_OF_MEMORY);
        //printf("c: %p, %p\n", c, ptr);
        int t = curl_easy_setopt(c, CURLOPT_PRIVATE, ptr);
        if(t != CURLE_OK){
            Safefree(ptr);
            curl_easy_cleanup(c);
            XSRETURN_IV(t);
        }
        SV *sv = sv_newmortal();
        SvPOK_only(sv);
        sv_setref_pv(sv, "http::curl::easy", (void *)c);
        SvREADONLY_on(sv);
        ((p_curl_easy *)ptr)->curle = SvRV(sv); // no need to increase refcount
        //printf("curl_easy_init: %p, %p, %p, %d\n", c, ptr, ((p_curl_easy *)ptr)->curle, SvREFCNT(SvRV(sv)));
        ST(0) = sv;
        XSRETURN(1);

void L_curl_easy_cleanup(SV *e_http=NULL)
    PPCODE:
        dTHX;
        dSP;
        if(!THISSvOK(e_http))
            XSRETURN_UNDEF;
        //printf("e: %p %p %p\n", (CURL *)THIS(e_http), e_http, SvRV(e_http));
        // fetch ptr to private
        void *p = NULL;
        int r = curl_easy_getinfo((CURL *)THIS(e_http), CURLINFO_PRIVATE, &p);
        curl_easy_setopt((CURL *)THIS(e_http), CURLOPT_PRIVATE, NULL);
        // cleanup
        curl_easy_cleanup((CURL *)THIS(e_http));
        // free ptr
        if(r == CURLE_OK && p){
            //printf("destroy_easy_cbs: %p, %p\n", (CURL *)THIS(e_http), p);
            // clear possible CURLOPT_ERRORBUFFER
            if(((p_curl_easy *)p)->errbuffer){
                //printf("destroy_easy_errbuffer: %p, %p\n", (CURL *)THIS(e_http), p);
                SvREFCNT_dec(((p_curl_easy *)p)->errbuffer);
                ((p_curl_easy *)p)->errbuffer = NULL;
            }
            if(((p_curl_easy *)p)->postfields){
                //printf("destroy_easy_postfields: %p, %p\n", (CURL *)THIS(e_http), p);
                SvREFCNT_dec(((p_curl_easy *)p)->postfields);
                ((p_curl_easy *)p)->postfields = NULL;
            }
            if(((p_curl_easy *)p)->private){
                //printf("destroy_easy_private: %p, %p\n", (CURL *)THIS(e_http), p);
                SvREFCNT_dec(((p_curl_easy *)p)->private);
                ((p_curl_easy *)p)->private = NULL;
            }
            if(((p_curl_easy *)p)->curlu){
                //printf("destroy_easy_curlu: %p, %p\n", (CURL *)THIS(e_http), p);
                SvREFCNT_dec(((p_curl_easy *)p)->curlu);
                ((p_curl_easy *)p)->curlu = NULL;
            }
            if(((p_curl_easy *)p)->fd_stderr_sv){
                //printf("destroy_easy_fd_stderr_sv: %p, %p\n", (CURL *)THIS(e_http), p);
                SvREFCNT_dec(((p_curl_easy *)p)->fd_stderr_sv);
                ((p_curl_easy *)p)->fd_stderr_sv = NULL;
            }
            if(((p_curl_easy *)p)->headers_slist){
                //printf("destroy_easy_headers_slist: %p, %p\n", (CURL *)THIS(e_http), p);
                curl_slist_free_all(((p_curl_easy *)p)->headers_slist);
                ((p_curl_easy *)p)->headers_slist = NULL;
            }
            ((p_curl_easy *)p)->curle = NULL; // we're about to free ourself (DESTROY SV)
            for(int f=0; f<MAX_CB; f++){
                p_curl_cb *cbe = &((p_curl_easy *)p)->cbs[f];
                //printf("destroy_easy_cb: %d, %p, %p\n", f, cbe->cb, cbe->cd);
                if(cbe->cb)
                    SvREFCNT_dec(cbe->cb);
                if(cbe->cd)
                    SvREFCNT_dec(cbe->cd);
            }
            Safefree(p);
        }
        SV *sv_e_http = SvRV(e_http);
        sv_setref_pv(sv_e_http, NULL, NULL);
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
        ST(0) = sv_2mortal(newSVpv(s, 0));
        XSRETURN(1);

void L_curl_easy_setopt(SV *e_http=NULL, int c_opt=0, SV *value=&PL_sv_undef)
    PREINIT:
        int r = -1;
        struct curl_slist *_vs = NULL;
        AV *av = NULL;
    PPCODE:
        dTHX;
        dSP;
        if(!THISSvOK(e_http))
            XSRETURN_UNDEF;

        //printf("curl_easy_setopt: %p %d %p %s\n", (CURL *)THIS(e_http), c_opt, value, (curl_easy_option_by_id(c_opt))->name);
        if(c_opt >= CURLOPTTYPE_LONG && c_opt < CURLOPTTYPE_OBJECTPOINT
            || c_opt == CURLOPTTYPE_VALUES){
            if(value && SvOK(value)){
                if(!looks_like_number(value))
                    XSRETURN_IV(CURLE_BAD_FUNCTION_ARGUMENT);
                long _vl = (long)SvIV(value);
                r = curl_easy_setopt((CURL *)THIS(e_http), c_opt, _vl);
            } else {
                r = curl_easy_setopt((CURL *)THIS(e_http), c_opt, 0);
            }
        } else if(c_opt >= CURLOPTTYPE_OBJECTPOINT && c_opt < CURLOPTTYPE_FUNCTIONPOINT){
            void *p = NULL;
            int cb_indx = -1, f = 0, t = 0;
            SV *prev_sv = NULL;
            SV *dt = NULL;
            if(value && SvOK(value))
                dt = value;
            switch(c_opt){
                case CURLOPT_SHARE:
                    XSRETURN_IV(CURLE_NOT_BUILT_IN);
                    break;
                case CURLOPT_CHUNK_DATA:
                    XSRETURN_IV(CURLE_NOT_BUILT_IN);
                    break;
                case CURLOPT_PRIVATE:
                    //printf("CURLOPT_PRIVATE\n");
                    t = curl_easy_getinfo((CURL *)THIS(e_http), CURLINFO_PRIVATE, &p);
                    if(t == CURLE_OK && p){
                        if(((p_curl_easy *)p)->private){
                            SvREFCNT_dec(((p_curl_easy *)p)->private);
                        }
                        ((p_curl_easy *)p)->private = NULL;
                    }
                    if(dt){
                        ((p_curl_easy *)p)->private = dt;
                        SvREFCNT_inc(dt);
                    }
                    r = CURLE_OK;
                    f = 1;
                    break;
                case CURLOPT_QUOTE:
                case CURLOPT_POSTQUOTE:
                case CURLOPT_TELNETOPTIONS:
                case CURLOPT_PREQUOTE:
                case CURLOPT_HTTP200ALIASES:
                case CURLOPT_MAIL_RCPT:
                case CURLOPT_RESOLVE:
                case CURLOPT_PROXYHEADER:
                case CURLOPT_CONNECT_TO:
                    XSRETURN_IV(CURLE_NOT_BUILT_IN);
                    break;
                case CURLOPT_HTTPHEADER:
                    av = (AV *)SvRV(dt);
                    for(int i=0; i<=av_len(av); i++){
                        SV **sv = av_fetch(av, i, 0);
                        if(sv && SvPOK(*sv)){
                            _vs = curl_slist_append(_vs, SvPV_nolen(*sv));
                        }
                    }
                    CURL *ce = (CURL *)THIS(e_http);
                    t = curl_easy_getinfo(ce, CURLINFO_PRIVATE, &p);
                    if(t == CURLE_OK && p){
                        if(((p_curl_easy *)p)->headers_slist){
                            curl_slist_free_all(((p_curl_easy *)p)->headers_slist);
                        }
                        ((p_curl_easy *)p)->headers_slist = _vs;
                    }
                    r = curl_easy_setopt((CURL *)THIS(e_http), c_opt, _vs);
                    f = 1;
                    break;
                case CURLOPT_POSTFIELDS:
                    if(dt && !SvPOK(dt))
                        XSRETURN_IV(CURLE_BAD_FUNCTION_ARGUMENT);
                    t = curl_easy_getinfo((CURL *)THIS(e_http), CURLINFO_PRIVATE, &p);
                    if(t == CURLE_OK && p){
                        if(((p_curl_easy *)p)->postfields){
                            SvREFCNT_dec(((p_curl_easy *)p)->postfields);
                        }
                        ((p_curl_easy *)p)->postfields = NULL;
                    }
                    if(dt){
                        //printf("set postfields %p\n", dt);
                        ((p_curl_easy *)p)->postfields = dt;
                        if(SvMAGICAL(dt))
                            SvGETMAGIC(dt);
                        SvREFCNT_inc(dt);
                        //printf("set postfields %p %p %s\n", dt, SvPVX(dt), SvPVX(dt));
                        r = curl_easy_setopt((CURL *)THIS(e_http), c_opt, SvPVX(dt));
                    } else {
                        r = curl_easy_setopt((CURL *)THIS(e_http), c_opt, NULL);
                    }
                    f = 1;
                    break;
                case CURLOPT_CURLU:
                    if(dt){
                        //printf("CURLOPT_CURLU 1\n");
                        if(!sv_isa(dt, "http::curl::url"))
                            XSRETURN_IV(CURLE_BAD_FUNCTION_ARGUMENT);
                        //printf("CURLOPT_CURLU 2\n");
                    }
                    t = curl_easy_getinfo((CURL *)THIS(e_http), CURLINFO_PRIVATE, &p);
                    if(t == CURLE_OK && p){
                        if(((p_curl_easy *)p)->curlu){
                            SvREFCNT_dec(((p_curl_easy *)p)->curlu);
                        }
                        ((p_curl_easy *)p)->curlu = NULL;
                    }
                    if(dt){
                        ((p_curl_easy *)p)->curlu = dt;
                        SvREFCNT_inc(dt);
                        //printf("CURLOPT_CURLU 4: %p\n", THIS(dt));
                        r = curl_easy_setopt((CURL *)THIS(e_http), c_opt, (CURLU *)THIS(dt));
                    } else {
                        r = curl_easy_setopt((CURL *)THIS(e_http), c_opt, NULL);
                    }
                    f = 1;
                    break;
                case CURLOPT_ERRORBUFFER:
                    t = curl_easy_getinfo((CURL *)THIS(e_http), CURLINFO_PRIVATE, &p);
                    if(t == CURLE_OK && p){
                        if(((p_curl_easy *)p)->errbuffer){
                            SvREFCNT_dec(((p_curl_easy *)p)->errbuffer);
                        }
                        ((p_curl_easy *)p)->errbuffer = NULL;
                    }
                    if(dt){
                        // SvCLEAR makes 0 bytes size PV
                        SvPVCLEAR(dt);
                        if(SvLEN(dt) < CURL_ERROR_SIZE+1){
                            SvGROW(dt, CURL_ERROR_SIZE+1);
                            SvCUR_set(dt, CURL_ERROR_SIZE);
                        }
                        memzero(SvPVX(dt), CURL_ERROR_SIZE+1);
                        SvPOK_on(dt);
                        SvPOK_only(dt);
                        SvSETMAGIC(dt);
                        SvREFCNT_inc(dt);
                        ((p_curl_easy *)p)->errbuffer = dt;
                        r = curl_easy_setopt((CURL *)THIS(e_http), c_opt, SvPVX(dt));
                    } else {
                        r = curl_easy_setopt((CURL *)THIS(e_http), c_opt, NULL);
                    }
                    f = 1;
                    break;
                case CURLOPT_DEBUGDATA:
                    cb_indx = CB_DEBUGFUNCTION;
                    break;
                case CURLOPT_IOCTLDATA:
                    cb_indx = CB_IOCTLFUNCTION;
                    break;
                case CURLOPT_SSL_CTX_DATA:
                    cb_indx = CB_SSL_CTX_FUNCTION;
                    break;
                case CURLOPT_STDERR:
                    // if there is no callback set, we can set this as the FILE
                    // * directly, but we need to keep the SV IO::Handle in our
                    // private struct. If there is a callback set, we keep things
                    // as they were
                    t = curl_easy_getinfo((CURL *)THIS(e_http), CURLINFO_PRIVATE, &p);
                    if(t != CURLE_OK)
                        XSRETURN_IV(CURLE_BAD_FUNCTION_ARGUMENT);

                    // whether dt == NULL or not, we need to clear the previous var
                    if(((p_curl_easy *)p)->fd_stderr_sv){
                        SvREFCNT_dec(((p_curl_easy *)p)->fd_stderr_sv);
                    }
                    ((p_curl_easy *)p)->fd_stderr_sv = dt;

                    if(dt){
                        // set, we need to keep the SV IO::Handle in our
                        // private struct, tell perl to keep it alive
                        SvREFCNT_inc(((p_curl_easy *)p)->fd_stderr_sv);

                        if(!SvROK(dt) || SvTYPE(SvRV(dt)) != SVt_PVGV)
                            XSRETURN_IV(CURLE_BAD_FUNCTION_ARGUMENT);
                        GV *gv = (GV *)SvRV(dt);
                        if(!gv || !GvIO(gv))
                            XSRETURN_IV(CURLE_BAD_FUNCTION_ARGUMENT);
                        int fd = PerlIO_fileno(IoIFP(GvIOn(gv)));
                        if(fd == -1)
                            XSRETURN_IV(CURLE_BAD_FUNCTION_ARGUMENT);
                        FILE *fp = fdopen(fd, "r");
                        if(fp){
                            r = curl_easy_setopt((CURL *)THIS(e_http), c_opt, fp);
                        } else {
                            XSRETURN_IV(CURLE_BAD_FUNCTION_ARGUMENT);
                        }
                    } else {
                        r = curl_easy_setopt((CURL *)THIS(e_http), c_opt, fdopen(2,"a"));
                    }
                    f = 1;
                    break;
                case CURLOPT_READDATA:
                    // if there is no callback set, we can set this as the FILE
                    // * directly, but we need to keep the SV IO::Handle in our
                    // private struct. If there is a callback set, we keep things
                    // as they were
                    t = curl_easy_getinfo((CURL *)THIS(e_http), CURLINFO_PRIVATE, &p);
                    if(t != CURLE_OK)
                        XSRETURN_IV(CURLE_BAD_FUNCTION_ARGUMENT);

                    // whether dt == NULL or not, we need to clear the previous var
                    if(((p_curl_easy *)p)->cbs[CB_READFUNCTION].cd){
                        SvREFCNT_dec(((p_curl_easy *)p)->cbs[CB_READFUNCTION].cd);
                    }
                    ((p_curl_easy *)p)->cbs[CB_READFUNCTION].cd = dt;

                    //printf("CURLOPT_READDATA 0\n");
                    if(dt){
                        // set, we need to keep the SV IO::Handle in our
                        SvREFCNT_inc(((p_curl_easy *)p)->cbs[CB_READFUNCTION].cd);

                        //printf("CURLOPT_READDATA 1\n");
                        if(((p_curl_easy *)p)->cbs[CB_READFUNCTION].cb == NULL){
                            if(!SvROK(dt) || SvTYPE(SvRV(dt)) != SVt_PVGV)
                                XSRETURN_IV(CURLE_OK);
                            GV *gv = (GV *)SvRV(dt);
                            if(!gv || !GvIO(gv))
                                XSRETURN_IV(CURLE_BAD_FUNCTION_ARGUMENT);
                            //printf("CURLOPT_READDATA 2\n");
                            int fd = PerlIO_fileno(IoIFP(GvIOn(gv)));
                            if(fd == -1)
                                XSRETURN_IV(CURLE_BAD_FUNCTION_ARGUMENT);
                            FILE *fp = fdopen(fd, "r");
                            if(fp){
                                //printf("CURLOPT_READDATA 3 %d\n", fd);
                                r = curl_easy_setopt((CURL *)THIS(e_http), c_opt, fp);
                            } else {
                                XSRETURN_IV(CURLE_BAD_FUNCTION_ARGUMENT);
                            }
                            f = 1;
                        } else {
                            //printf("CURLOPT_READDATA 4 %p\n", ((p_curl_easy *)p)->cbs[CB_READFUNCTION].cd);
                            cb_indx = CB_READFUNCTION;
                        }
                    } else {
                        //printf("CURLOPT_READDATA 5 %p\n", ((p_curl_easy *)p)->cbs[CB_READFUNCTION].cd);
                        r = curl_easy_setopt((CURL *)THIS(e_http), c_opt, fdopen(0,"r"));
                        f = 1;
                    }
                    break;
                case CURLOPT_WRITEDATA:
                    // if there is no callback set, we can set this as the FILE
                    // * directly, but we need to keep the SV IO::Handle in our
                    // private struct. If there is a callback set, we keep things
                    // as they were
                    t = curl_easy_getinfo((CURL *)THIS(e_http), CURLINFO_PRIVATE, &p);
                    if(t != CURLE_OK)
                        XSRETURN_IV(CURLE_BAD_FUNCTION_ARGUMENT);

                    // whether dt == NULL or not, we need to clear the previous var
                    if(((p_curl_easy *)p)->cbs[CB_WRITEFUNCTION].cd){
                        SvREFCNT_dec(((p_curl_easy *)p)->cbs[CB_WRITEFUNCTION].cd);
                    }
                    ((p_curl_easy *)p)->cbs[CB_WRITEFUNCTION].cd = dt;

                    //printf("CURLOPT_WRITEDATA 0\n");
                    if(dt){
                        // set, we need to keep the SV IO::Handle in our
                        SvREFCNT_inc(((p_curl_easy *)p)->cbs[CB_WRITEFUNCTION].cd);

                        //printf("CURLOPT_WRITEDATA 1\n");
                        if(((p_curl_easy *)p)->cbs[CB_WRITEFUNCTION].cb == NULL){
                            if(!SvROK(dt) || SvTYPE(SvRV(dt)) != SVt_PVGV)
                                XSRETURN_IV(CURLE_OK);
                            GV *gv = (GV *)SvRV(dt);
                            if(!gv || !GvIO(gv))
                                XSRETURN_IV(CURLE_BAD_FUNCTION_ARGUMENT);
                            //printf("CURLOPT_WRITEDATA 2\n");
                            int fd = PerlIO_fileno(IoIFP(GvIOn(gv)));
                            if(fd == -1)
                                XSRETURN_IV(CURLE_BAD_FUNCTION_ARGUMENT);
                            FILE *fp = fdopen(fd, "r");
                            if(fp){
                                //printf("CURLOPT_WRITEDATA 3 %d\n", fd);
                                r = curl_easy_setopt((CURL *)THIS(e_http), c_opt, fp);
                            } else {
                                XSRETURN_IV(CURLE_BAD_FUNCTION_ARGUMENT);
                            }
                            f = 1;
                        } else {
                            //printf("CURLOPT_WRITEDATA 4 %p\n", ((p_curl_easy *)p)->cbs[CB_WRITEFUNCTION].cd);
                            cb_indx = CB_WRITEFUNCTION;
                        }
                    } else {
                        //printf("CURLOPT_WRITEDATA 5 %p\n", ((p_curl_easy *)p)->cbs[CB_WRITEFUNCTION].cd);
                        r = curl_easy_setopt((CURL *)THIS(e_http), c_opt, fdopen(1,"r"));
                        f = 1;
                    }
                    break;
                case CURLOPT_PREREQDATA:
                    cb_indx = CB_PREREQFUNCTION;
                    break;
                case CURLOPT_SEEKDATA:
                    cb_indx = CB_SEEKFUNCTION;
                    break;
                case CURLOPT_SOCKOPTDATA:
                    cb_indx = CB_SOCKOPTFUNCTION;
                    break;
                case CURLOPT_CLOSESOCKETDATA:
                    cb_indx = CB_CLOSESOCKETFUNCTION;
                    break;
                case CURLOPT_OPENSOCKETDATA:
                    cb_indx = CB_OPENSOCKETFUNCTION;
                    break;
                case CURLOPT_HEADERDATA:
                    // if there is no callback set, we can set this as the FILE
                    // * directly, but we need to keep the SV IO::Handle in our
                    // private struct. If there is a callback set, we keep things
                    // as they were
                    //printf("CURLOPT_HEADERDATA ONE\n");
                    t = curl_easy_getinfo((CURL *)THIS(e_http), CURLINFO_PRIVATE, &p);
                    if(t != CURLE_OK)
                        XSRETURN_IV(CURLE_BAD_FUNCTION_ARGUMENT);

                    // whether dt == NULL or not, we need to clear the previous var
                    if(((p_curl_easy *)p)->cbs[CB_HEADERFUNCTION].cd){
                        SvREFCNT_dec(((p_curl_easy *)p)->cbs[CB_HEADERFUNCTION].cd);
                    }
                    ((p_curl_easy *)p)->cbs[CB_HEADERFUNCTION].cd = dt;

                    //printf("CURLOPT_HEADERDATA 0\n");
                    if(dt){
                        // set, we need to keep the SV IO::Handle in our
                        SvREFCNT_inc(((p_curl_easy *)p)->cbs[CB_HEADERFUNCTION].cd);

                        //printf("CURLOPT_HEADERDATA 1\n");
                        if(((p_curl_easy *)p)->cbs[CB_HEADERFUNCTION].cb == NULL){
                            //printf("CURLOPT_HEADERDATA 2 %p\n", dt);
                            if(!SvROK(dt) || SvTYPE(SvRV(dt)) != SVt_PVGV)
                                XSRETURN_IV(CURLE_OK);
                            GV *gv = (GV *)SvRV(dt);
                            if(!gv || !GvIO(gv))
                                XSRETURN_IV(CURLE_BAD_FUNCTION_ARGUMENT);
                            //printf("CURLOPT_HEADERDATA 2\n");
                            int fd = PerlIO_fileno(IoIFP(GvIOn(gv)));
                            if(fd == -1)
                                XSRETURN_IV(CURLE_BAD_FUNCTION_ARGUMENT);
                            FILE *fp = fdopen(fd, "r");
                            if(fp){
                                //printf("CURLOPT_HEADERDATA 3 %d\n", fd);
                                r = curl_easy_setopt((CURL *)THIS(e_http), c_opt, fp);
                            } else {
                                XSRETURN_IV(CURLE_BAD_FUNCTION_ARGUMENT);
                            }
                            f = 1;
                        } else {
                            //printf("CURLOPT_HEADERDATA 4 %p\n", ((p_curl_easy *)p)->cbs[CB_WRITEFUNCTION].cd);
                            cb_indx = CB_HEADERFUNCTION;
                        }
                    } else {
                        //printf("CURLOPT_HEADERDATA 5 %p\n", ((p_curl_easy *)p)->cbs[CB_WRITEFUNCTION].cd);
                        r = curl_easy_setopt((CURL *)THIS(e_http), c_opt, fdopen(1,"r"));
                        f = 1;
                    }
                    break;
                case CURLOPT_HSTSREADDATA:
                    cb_indx = CB_HSTSREADFUNCTION;
                    break;
                case CURLOPT_HSTSWRITEDATA:
                    cb_indx = CB_HSTSWRITEFUNCTION;
                    break;
                case CURLOPT_RESOLVER_START_DATA:
                    cb_indx = CB_RESOLVER_START_FUNCTION;
                    break;
                case CURLOPT_TRAILERDATA:
                    cb_indx = CB_TRAILERFUNCTION;
                    break;
                case CURLOPT_XFERINFODATA:
                    cb_indx = CB_XFERINFOFUNCTION;
                    break;
                default:
                    if(dt && SvOK(dt)){
                        if(!SvPOK(dt))
                            XSRETURN_IV(CURLE_BAD_FUNCTION_ARGUMENT);
                        char *_vc = (char *)SvPV_nolen(dt);
                        r = curl_easy_setopt((CURL *)THIS(e_http), c_opt, _vc);
                    } else {
                        r = curl_easy_setopt((CURL *)THIS(e_http), c_opt, NULL);
                    }
                    f = 1;
                    break;
            }
            if(!f){
                if(cb_indx != -1){
                    r = cd_setup_pvt((CURL *)THIS(e_http), cb_indx, dt, &prev_sv);
                    if(r == CURLE_OK){
                        if(dt)
                            SvREFCNT_inc(dt);
                    }
                    if(prev_sv)
                        SvREFCNT_dec(prev_sv);
                } else {
                    XSRETURN_IV(CURLE_BAD_FUNCTION_ARGUMENT);
                }
            }
        } else if(c_opt >= CURLOPTTYPE_FUNCTIONPOINT && c_opt < CURLOPTTYPE_OFF_T){
            switch(c_opt){
                case CURLOPT_SSH_KEYFUNCTION:
                case CURLOPT_SSH_HOSTKEYFUNCTION:
                case CURLOPT_CHUNK_BGN_FUNCTION:
                case CURLOPT_CHUNK_END_FUNCTION:
                case CURLOPT_CONV_FROM_UTF8_FUNCTION:
                case CURLOPT_CONV_TO_NETWORK_FUNCTION:
                case CURLOPT_CONV_FROM_NETWORK_FUNCTION:
                    XSRETURN_IV(CURLE_NOT_BUILT_IN);
                    break;
                default:
                    break;
            }
            int cb_indx = -1, t = -1;
            // NULL clears the FUNCTION/DATA combination
            SV *cb = NULL;
            SV *prev_sv = NULL;
            if(value && SvROK(value) && SvTYPE(SvRV(value)) == SVt_PVCV)
                cb = SvRV(value);
            if(value && SvROK(value) && SvTYPE(SvRV(value)) != SVt_PVCV)
                XSRETURN_IV(CURLE_BAD_FUNCTION_ARGUMENT);
            if(value && !SvROK(value))
                if(SvTYPE(value) == SVt_NULL)
                    cb = NULL;
                else
                    XSRETURN_IV(CURLE_BAD_FUNCTION_ARGUMENT);
            switch(c_opt){
                case CURLOPT_SSH_KEYFUNCTION:
                case CURLOPT_SSH_HOSTKEYFUNCTION:
                    XSRETURN_IV(CURLE_NOT_BUILT_IN);
                    break;
                case CURLOPT_DEBUGFUNCTION:
                    cb_indx = CB_DEBUGFUNCTION;
                    break;
                case CURLOPT_IOCTLFUNCTION:
                    cb_indx = CB_IOCTLFUNCTION;
                    break;
                case CURLOPT_SSL_CTX_FUNCTION:
                    cb_indx = CB_SSL_CTX_FUNCTION;
                    break;
                case CURLOPT_READFUNCTION:
                    cb_indx = CB_READFUNCTION;
                    break;
                case CURLOPT_WRITEFUNCTION:
                    cb_indx = CB_WRITEFUNCTION;
                    break;
                case CURLOPT_PREREQFUNCTION:
                    cb_indx = CB_PREREQFUNCTION;
                    break;
                case CURLOPT_SEEKFUNCTION:
                    cb_indx = CB_SEEKFUNCTION;
                    break;
                case CURLOPT_SOCKOPTFUNCTION:
                    cb_indx = CB_SOCKOPTFUNCTION;
                    break;
                case CURLOPT_CLOSESOCKETFUNCTION:
                    cb_indx = CB_CLOSESOCKETFUNCTION;
                    break;
                case CURLOPT_OPENSOCKETFUNCTION:
                    cb_indx = CB_OPENSOCKETFUNCTION;
                    break;
                case CURLOPT_HEADERFUNCTION:
                    cb_indx = CB_HEADERFUNCTION;
                    break;
                case CURLOPT_HSTSREADFUNCTION:
                    cb_indx = CB_HSTSREADFUNCTION;
                    break;
                case CURLOPT_HSTSWRITEFUNCTION:
                    cb_indx = CB_HSTSWRITEFUNCTION;
                    break;
                case CURLOPT_RESOLVER_START_FUNCTION:
                    cb_indx = CB_RESOLVER_START_FUNCTION;
                    break;
                case CURLOPT_TRAILERFUNCTION:
                    cb_indx = CB_TRAILERFUNCTION;
                    break;
                case CURLOPT_XFERINFOFUNCTION:
                    cb_indx = CB_XFERINFOFUNCTION;
                    break;
                default:
                    XSRETURN_IV(CURLE_BAD_FUNCTION_ARGUMENT);
                    break;
            }
            r = cb_setup_pvt((CURL *)THIS(e_http), cb_indx, cb, &prev_sv);
            // first increase refcount, then decrease the old one, else we
            // might GC the object while we are just reusing the same var
            if(r == CURLE_OK){
                if(cb)
                    SvREFCNT_inc(cb);
            }
            if(prev_sv){
                SvREFCNT_dec(prev_sv);
            }
            //printf("r2: %p %p %p\n", cb, prev_sv, value);
        } else if(c_opt >= CURLOPTTYPE_OFF_T && c_opt < CURLOPTTYPE_BLOB){
            if(value && SvOK(value)){
                if(!looks_like_number(value))
                    XSRETURN_IV(CURLE_BAD_FUNCTION_ARGUMENT);
                curl_off_t _vo = (curl_off_t)SvIV(value);
                r = curl_easy_setopt((CURL *)THIS(e_http), c_opt, _vo);
            } else {
                r = curl_easy_setopt((CURL *)THIS(e_http), c_opt, 0);
            }
        } else {
            XSRETURN_IV(CURLE_BAD_FUNCTION_ARGUMENT);
        }
        //printf("r3: %d\n", r);
        if(r == -1)
            XSRETURN_IV(CURLE_BAD_FUNCTION_ARGUMENT);
        if(r != CURLE_OK)
            XSRETURN_IV(r);
        XSRETURN_IV(r);

void L_curl_easy_option_by_name(...)
    PPCODE:
        dTHX;
#if (LIBCURL_VERSION_NUM >= 0x073f00)
        dSP;
        if(items != 1)
            XSRETURN_UNDEF;
        SV *name = POPs;
        if(!name || !SvPOK(name))
            XSRETURN_UNDEF;
        const struct curl_easyoption *opt = curl_easy_option_by_name(SvPV_nolen(name));
        if(!opt){
            XSRETURN_UNDEF;
        }
        HV *rh = newHV();
        hv_store(rh, "name"  , 4, newSVpv(opt->name, 0), 0);
        hv_store(rh, "type"  , 4, newSViv(opt->type)   , 0);
        hv_store(rh, "flags" , 5, newSViv(opt->flags)  , 0);
        hv_store(rh, "id"    , 2, newSViv(opt->id)     , 0);
        ST(0) = sv_2mortal(newRV_inc((SV *)rh));
        XSRETURN(1);
#else
        croak("curl_easy_option_by_name is not supported in this version of libcurl");
#endif

void L_curl_easy_option_by_id(...)
    PPCODE:
        dTHX;
#if (LIBCURL_VERSION_NUM >= 0x073f00)
        dSP;
        if(items != 1)
            XSRETURN_UNDEF;
        SV *id = POPs;
        if(!id || !looks_like_number(id))
            XSRETURN_UNDEF;
        const struct curl_easyoption *opt = curl_easy_option_by_id(SvIV(id));
        if(!opt)
            XSRETURN_UNDEF;
        HV *rh = newHV();
        hv_store(rh, "name"  , 4, newSVpv(opt->name, 0), 0);
        hv_store(rh, "type"  , 4, newSViv(opt->type)   , 0);
        hv_store(rh, "flags" , 5, newSViv(opt->flags)  , 0);
        hv_store(rh, "id"    , 2, newSViv(opt->id)     , 0);
        ST(0) = sv_2mortal(newRV_inc((SV *)rh));
        XSRETURN(1);
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
        void *old_p = NULL;
        int r = curl_easy_getinfo(c, CURLINFO_PRIVATE, &old_p);
        // don't fetch CURLOPT_PRIVATE, curl_easy_duphandle copies it, but we
        // won't do anything with it, as it's part of the original e_http
        // handle: also DON'T clear that, just the ptr
        void *ptr = NULL;
        Newxz(ptr, 1, p_curl_easy);
        if(!ptr){
            curl_easy_cleanup(c);
            XSRETURN_IV(CURLE_OUT_OF_MEMORY);
        }
        int d = curl_easy_setopt(c, CURLOPT_PRIVATE, ptr);
        if(d != CURLE_OK){
            Safefree(ptr);
            curl_easy_cleanup(c);
            croak("Problem setting CURLOPT_PRIVATE: %s", curl_easy_strerror(d));
        }

        // fetch from the original handle the FUNCTION opts
        //printf("d: %lld, %p, new P: %p, old P: %p, old H: %p\n", (long long)c, c, ptr, old_p, (CURL *)THIS(e_http));
        if(r == CURLE_OK && old_p){
            // copy a CURLOPT_ERRORBUFFER case if there
            if(((p_curl_easy *)old_p)->errbuffer){
                SvREFCNT_inc(((p_curl_easy *)old_p)->errbuffer);
                ((p_curl_easy *)ptr)->errbuffer = ((p_curl_easy *)old_p)->errbuffer;
            }
            if(((p_curl_easy *)old_p)->postfields){
                SvREFCNT_inc(((p_curl_easy *)old_p)->postfields);
                ((p_curl_easy *)ptr)->postfields = ((p_curl_easy *)old_p)->postfields;
            }
            if(((p_curl_easy *)old_p)->private){
                SvREFCNT_inc(((p_curl_easy *)old_p)->private);
                ((p_curl_easy *)ptr)->private = ((p_curl_easy *)old_p)->private;
            }
            if(((p_curl_easy *)old_p)->curlu){
                SvREFCNT_inc(((p_curl_easy *)old_p)->curlu);
                ((p_curl_easy *)ptr)->curlu = ((p_curl_easy *)old_p)->curlu;
            }
            if(((p_curl_easy *)old_p)->fd_stderr_sv){
                SvREFCNT_inc(((p_curl_easy *)old_p)->fd_stderr_sv);
                ((p_curl_easy *)ptr)->fd_stderr_sv = ((p_curl_easy *)old_p)->fd_stderr_sv;
            }
            // copy all callback functions
            for(int f=0; f<MAX_CB; f++){
                // set NULL, but not needed as we used Newxz()
                ((p_curl_easy *)ptr)->cbs[f].cb = NULL;
                ((p_curl_easy *)ptr)->cbs[f].cd = NULL;

                p_curl_cb *cb_orig = &((p_curl_easy *)old_p)->cbs[f];
                int p_set = 0;
                if(cb_orig->cb){
                    //printf("dup_ptr 1: %d, cb: %p, %p\n", f, cb_orig->cb, ptr);
                    SvREFCNT_inc((SV *)cb_orig->cb);
                    ((p_curl_easy *)ptr)->cbs[f].cb = cb_orig->cb;
                    int e = curl_easy_setopt(c, curl_cb_opts[f].d, ptr);
                    if(e != CURLE_OK){
                        SvREFCNT_dec((SV *)cb_orig->cd);
                        Safefree(ptr);
                        curl_easy_cleanup(c);
                        croak("Problem setting callback index: %d: %s", f, curl_easy_strerror(e));
                    } else {
                        p_set = 1;
                    }
                }
                if(cb_orig->cd){
                    SvREFCNT_inc((SV *)cb_orig->cd);
                    ((p_curl_easy *)ptr)->cbs[f].cd = cb_orig->cd;
                    //printf("dup_ptr 2: %d, cd: %p, %p\n", f, cb_orig->cd, ptr);
                    if(!p_set){
                        int e = curl_easy_setopt(c, curl_cb_opts[f].d, ptr);
                        if(e != CURLE_OK){
                            SvREFCNT_dec((SV *)cb_orig->cd);
                            Safefree(ptr);
                            curl_easy_cleanup(c);
                            croak("Problem setting callback index: %d: %s", f, curl_easy_strerror(e));
                        }
                    }
                }
                //printf("dup: %d, cb: %p, cd: %p\n", f, cb_orig->cb, cb_orig->cd);
            }
        }
        SV *sv = sv_newmortal();
        sv_setref_pv(sv, "http::curl::easy", (void *)c);
        SvREADONLY_on(sv);
        ((p_curl_easy *)ptr)->curle = SvRV(sv); // no need to increase refcount
        ST(0) = sv;
        XSRETURN(1);

void L_curl_easy_escape(...)
    PREINIT:
        SV *url=NULL;
        char *s = NULL;
    PPCODE:
        dTHX;
        dSP;
        if(items < 1)
            XSRETURN_UNDEF;
        url = POPs;
        if(!url || !SvOK(url) || !SvPOK(url))
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
        SV *sv = newSVpv(s, 0);
        curl_free(s);
        ST(0) = sv_2mortal(sv);
        XSRETURN(1);

void L_curl_easy_unescape(...)
    PREINIT:
        SV *url=NULL;
        char *s = NULL;
    PPCODE:
        dTHX;
        dSP;
        if(items < 1)
            XSRETURN_UNDEF;
        url = POPs;
        if(!url || !SvOK(url) || !SvPOK(url))
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
        SV *sv = newSVpv(s, 0);
        curl_free(s);
        ST(0) = sv_2mortal(sv);
        XSRETURN(1);

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
        //printf("c_info: %d\n", c_info);
        if(c_info == 0)
            XSRETURN_UNDEF;
        if(c_info == CURLINFO_PRIVATE){
            void *p = NULL;
            r = curl_easy_getinfo((CURL *)THIS(e_http), c_info, &p);
            if(r != CURLE_OK)
                XSRETURN_UNDEF;
            if(p){
                SV *sv = (SV *)((p_curl_easy *)p)->private;
                ST(0) = sv;
                XSRETURN(1);
            } else {
                XSRETURN_UNDEF;
            }
        } else
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
        XSRETURN_IV(0);

void L_curl_easy_recv(SV *e_http=NULL, SV *data=NULL, IV max_sz=0)
    PREINIT:
        int r = 0;
        size_t recv_sz = 0;
    PPCODE:
        dTHX;
        dSP;
        if(!THISSvOK(e_http))
            XSRETURN_UNDEF;
        if(max_sz == 0)
            XSRETURN_IV(0);
        SV *buf = newSV(max_sz);
        SvPOK_only(buf);
        r = curl_easy_recv((CURL *)THIS(e_http), SvPVX(buf), max_sz, &recv_sz);
        if(r != CURLE_OK)
            XSRETURN_IV(r);
        SvCUR_set(buf, recv_sz);
        if(data){
            if(!SvOK(data)){
                //printf("recv append: %d\n", (int)recv_sz);
                sv_setsv(data, buf);
            } else {
                //printf("recv append: %d\n", (int)recv_sz);
                sv_catpvn(data, SvPVX(buf), recv_sz);
                SAVEFREESV(buf);
                buf = NULL;
            }
        }
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
        ST(0) = sv;
        XSRETURN(1);

void L_curl_multi_cleanup(SV *m_http=NULL)
    PREINIT:
        int r = 0;
    PPCODE:
        dTHX;
        dSP;
        if(!THISSvOK(m_http))
            XSRETURN_IV(CURLM_BAD_HANDLE);
        CURLM *m = (CURLM *)THIS(m_http);
        //printf("multi_cleanup: %p\n", m);
        // go via DESTROY, as we have to destroy SV's too
#if (LIBCURL_VERSION_NUM >= 0x080400)
        CURL **e = curl_multi_get_handles(m);
        if(e){
            //printf("multi_cleanup_multi_handles: %p, %p\n", m, e);
            for(int i=0; e[i]; i++){
                curl_multi_remove_handle(m, (CURL *)e[i]);
                void *p = NULL;
                int r = curl_easy_getinfo((CURL *)e[i], CURLINFO_PRIVATE, &p);
                if(r == CURLE_OK && p && ((p_curl_easy *)p)->curle){
                    SvREFCNT_dec(((p_curl_easy *)p)->curle);
                }
            }
            curl_free(e);
        }
#endif
        r = curl_multi_cleanup(m);
        if(r != CURLM_OK){
            warn("curl_multi_cleanup failed: %s, 0x%p", curl_multi_strerror(r), m);
            XSRETURN_IV(r);
        }
        SV *sv_m_http = SvRV(m_http);
        sv_setref_pv(sv_m_http, NULL, NULL);
        sv_setref_pv(m_http, NULL, NULL);
        XSRETURN_IV(CURLM_OK);

void L_curl_multi_wakeup(SV *m_http=NULL)
    PPCODE:
        dTHX;
#if (LIBCURL_VERSION_NUM >= 0x073f00)
        dSP;
        if(!THISSvOK(m_http))
            XSRETURN_IV(CURLM_BAD_HANDLE);
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
            XSRETURN_IV(CURLM_BAD_HANDLE);
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
            XSRETURN_IV(CURLM_BAD_HANDLE);
        if(!THISSvOK(e_http))
            XSRETURN_IV(CURLM_BAD_EASY_HANDLE);
        //printf("ADD 1: %p, %p, %d\n", (CURLM *)THIS(m_http), (CURL *)THIS(e_http), SvREFCNT(SvRV(e_http)));
        int r = curl_multi_add_handle((CURLM *)THIS(m_http), (CURL *)THIS(e_http));
        if(r != CURLM_OK)
            XSRETURN_IV(r);
        SvREFCNT_inc(SvRV(e_http));
        //printf("ADD 2: %p, %p, %d\n", (CURLM *)THIS(m_http), (CURL *)THIS(e_http), SvREFCNT(SvRV(e_http)));
        XSRETURN_IV(r);

void L_curl_multi_remove_handle(SV *m_http=NULL, SV *e_http=NULL)
    PPCODE:
        dTHX;
        dSP;
        if(!THISSvOK(m_http))
            XSRETURN_IV(CURLM_BAD_HANDLE);
        if(!THISSvOK(e_http))
            XSRETURN_IV(CURLM_BAD_EASY_HANDLE);
        //printf("REMOVE: %p, %p\n", (CURLM *)THIS(m_http), (CURL *)THIS(e_http));
        void *p = NULL;
        int rp = curl_easy_getinfo((CURL *)THIS(e_http), CURLINFO_PRIVATE, &p);
        int r = curl_multi_remove_handle((CURLM *)THIS(m_http), (CURL *)THIS(e_http));
        if(r != CURLM_OK)
            XSRETURN_IV(r);
        if(rp == CURLE_OK && p){
            //printf("REMOVE: %p, %p, %p, %d, %p, %p, %d, %d\n", (CURLM *)THIS(m_http), (CURL *)THIS(e_http), p, rp, ((p_curl_easy *)p)->curle, SvRV(e_http), SvREFCNT(SvRV(e_http)), SvREFCNT(e_http));
            SvREFCNT_dec(SvRV(e_http));
        }
        XSRETURN_IV(r);

void L_curl_multi_strerror(int code)
    PPCODE:
        dTHX;
        dSP;
        const char *s = curl_multi_strerror(code);
        if(!s)
            XSRETURN_UNDEF;
        ST(0) = sv_2mortal(newSVpv(s, 0));
        XSRETURN(1);

void L_curl_multi_timeout(SV *m_http=NULL, SV *timeout = NULL)
    PREINIT:
        long l = 0;
    PPCODE:
        dTHX;
        dSP;
        if(!THISSvOK(m_http))
            XSRETURN_IV(CURLM_BAD_HANDLE);
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
            XSRETURN_IV(CURLM_BAD_HANDLE);
        CURLMsg *m = curl_multi_info_read((CURLM *)THIS(m_http), &r);
        if(msgs_in_queue != NULL){
            sv_setiv(msgs_in_queue, r);
        }
        if(!m)
            XSRETURN_UNDEF;
        void *p = NULL;
        int rp = curl_easy_getinfo(m->easy_handle, CURLINFO_PRIVATE, &p);
        HV *rh = newHV();
        hv_store(rh,"msg",3,newSViv(m->msg),0);
        hv_store(rh,"result",6,newSViv(m->data.result),0);
        if(p && rp == CURLE_OK && ((p_curl_easy *)p)->curle){
            hv_store(rh,"easy_handle",11,newRV_inc(((p_curl_easy *)p)->curle),0);
        } else {
            hv_store(rh,"easy_handle",11,&PL_sv_undef,0);
        }
        ST(0) = sv_2mortal(newRV_inc((SV*)rh));
        XSRETURN(1);

void L_curl_multi_setopt(SV *m_http=NULL, IV c_opt=0, SV *value=NULL)
    PREINIT:
        int r = -1;
    PPCODE:
        dTHX;
        dSP;
        if(!THISSvOK(m_http))
            XSRETURN_IV(CURLM_BAD_HANDLE);

        if(c_opt >= CURLOPTTYPE_LONG && c_opt < CURLOPTTYPE_OBJECTPOINT){
            if(!looks_like_number(value))
                XSRETURN_IV(CURLM_BAD_FUNCTION_ARGUMENT);
            long _vl = (long)SvIV(value);
            r = curl_multi_setopt((CURLM *)THIS(m_http), c_opt, _vl);
        } else if(c_opt >= CURLOPTTYPE_OBJECTPOINT && c_opt < CURLOPTTYPE_FUNCTIONPOINT){
            if(!SvPOK(value))
                XSRETURN_IV(CURLM_BAD_FUNCTION_ARGUMENT);
            char *_vc = (char *)SvPV_nolen(value);
            r = curl_multi_setopt((CURLM *)THIS(m_http), c_opt, _vc);
        } else if(c_opt >= CURLOPTTYPE_FUNCTIONPOINT && c_opt < CURLOPTTYPE_OFF_T){
            if(!SvROK(value) || SvTYPE(SvRV(value)) != SVt_PVCV)
                XSRETURN_IV(CURLM_BAD_FUNCTION_ARGUMENT);
            r = curl_multi_setopt((CURLM *)THIS(m_http), c_opt, SvRV(value));
        } else if(c_opt >= CURLOPTTYPE_OFF_T && c_opt < CURLOPTTYPE_BLOB){
            if(!looks_like_number(value))
                XSRETURN_IV(CURLM_BAD_FUNCTION_ARGUMENT);
            long _vb = (long)SvIV(value);
            r = curl_multi_setopt((CURLM *)THIS(m_http), c_opt, _vb);
        } else {
            XSRETURN_IV(CURLM_BAD_FUNCTION_ARGUMENT);
        }
        XSRETURN_IV(r);

void L_curl_multi_fdset(SV *m_http=NULL)
    PREINIT:
        fd_set r;
        fd_set w;
        fd_set e;
        int max = -1;
        int rt = 0;
    PPCODE:
        dTHX;
        dSP;
        if(!THISSvOK(m_http))
            XSRETURN_IV(CURLM_BAD_HANDLE);
        POPs;
        //printf("FDSET: %p\n", (CURLM *)THIS(m_http));
        AV *re = newAV();
        AV *we = newAV();
        AV *ee = newAV();
        FD_ZERO(&r);
        FD_ZERO(&w);
        FD_ZERO(&e);
        rt = curl_multi_fdset((CURLM *)THIS(m_http), &r, &w, &e, &max);
        if(rt != CURLM_OK){
            mXPUSHs(newSViv(rt));
            mXPUSHs(newRV_noinc((SV *)re));
            mXPUSHs(newRV_noinc((SV *)we));
            mXPUSHs(newRV_noinc((SV *)ee));
            XSRETURN(4);
        }
        for(int i=0; i<=max; i++){
            if(FD_ISSET(i, &r))
                av_push(re, newSViv(i));
            if(FD_ISSET(i, &w))
                av_push(we, newSViv(i));
            if(FD_ISSET(i, &e))
                av_push(ee, newSViv(i));
        }
        mXPUSHs(newSViv(rt));
        mXPUSHs(newRV_noinc((SV *)re));
        mXPUSHs(newRV_noinc((SV *)we));
        mXPUSHs(newRV_noinc((SV *)ee));
        XSRETURN(4);

void L_curl_multi_poll(SV *m_http=NULL, SV *extrafds=&PL_sv_undef, int timeout=0, SV *numfds=NULL)
    PPCODE:
        dTHX;
#if (LIBCURL_VERSION_NUM >= 0x073f00)
        dSP;
        int r = 0;
        int nfds = 0;
        if(!THISSvOK(m_http))
            XSRETURN_IV(CURLM_BAD_HANDLE);
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
            XSRETURN_IV(CURLM_BAD_HANDLE);
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
        CURL **e = curl_multi_get_handles((CURLM *)THIS(m_http));
        if(!e)
            XSRETURN_IV(CURLM_BAD_HANDLE);
        AV *av = newAV();
        for(int i=0; e[i]; i++){
            void *p = NULL;
            int r = curl_easy_getinfo(e[i], CURLINFO_PRIVATE, &p);
            if(r != CURLE_OK || !p || !((p_curl_easy *)p)->curle)
                continue;
            SvREFCNT_inc(((p_curl_easy *)p)->curle);
            av_push(av, newRV_inc(((p_curl_easy *)p)->curle));
        }
        curl_free(e);
        ST(0) = sv_2mortal(newRV_noinc((SV *)av));
        XSRETURN(1);
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
        CURLM *m = (CURLM *)THIS(m_http);
        //printf("destroy_multi: %p\n", m);
        // get all handles and remove them
#if (LIBCURL_VERSION_NUM >= 0x080400)
        CURL **e = curl_multi_get_handles(m);
        if(e){
            //printf("destroy_multi_handles: %p, %p\n", m, e);
            for(int i=0; e[i]; i++){
                //printf("destroy_multi_remove_handle: %p, %p\n", m, e[i]);
                curl_multi_remove_handle(m, (CURL *)e[i]);
                void *p = NULL;
                int r = curl_easy_getinfo((CURL *)e[i], CURLINFO_PRIVATE, &p);
                if(r == CURLE_OK && p && ((p_curl_easy *)p)->curle){
                    SvREFCNT_dec(((p_curl_easy *)p)->curle);
                }
            }
            curl_free(e);
        }
#endif
        int r = curl_multi_cleanup(m);
        if(r != CURLM_OK){
            warn("curl_multi_cleanup failed: %s, 0x%p", curl_multi_strerror(r), (CURLM *)THIS(m_http));
            XSRETURN_NO;
        }
        //printf("after_destroy_curl_multi: %p\n", m);
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
        CURL *c = (CURL *)THIS(e_http);
        //printf("destroy_easy: %p %p %p\n", c, e_http, SvRV(e_http));
        // fetch ptr to private
        void *p = NULL;
        int r = curl_easy_getinfo(c, CURLINFO_PRIVATE, &p);
        if(p)
            curl_easy_setopt(c, CURLOPT_PRIVATE, NULL);
        // cleanup
        curl_easy_cleanup(c);
        // free ptr
        if(r == CURLE_OK && p){
            //printf("destroy_easy_cbs: %p, %p, %d, %p, %p\n", c, p, SvREFCNT(SvRV(e_http)), SvRV(e_http), ((p_curl_easy *)p)->curle);
            // clear possible CURLOPT_ERRORBUFFER
            if(((p_curl_easy *)p)->errbuffer){
                //printf("destroy_easy_errbuffer: %p, %p\n", c, p);
                SvREFCNT_dec(((p_curl_easy *)p)->errbuffer);
                ((p_curl_easy *)p)->errbuffer = NULL;
            }
            if(((p_curl_easy *)p)->postfields){
                //printf("destroy_easy_postfields: %p, %p\n", c, p);
                SvREFCNT_dec(((p_curl_easy *)p)->postfields);
                ((p_curl_easy *)p)->postfields = NULL;
            }
            if(((p_curl_easy *)p)->private){
                //printf("destroy_easy_private: %p, %p\n", c, p);
                SvREFCNT_dec(((p_curl_easy *)p)->private);
                ((p_curl_easy *)p)->private = NULL;
            }
            if(((p_curl_easy *)p)->curlu){
                //printf("destroy_easy_curlu: %p, %p\n", c, p);
                SvREFCNT_dec(((p_curl_easy *)p)->curlu);
                ((p_curl_easy *)p)->curlu = NULL;
            }
            if(((p_curl_easy *)p)->fd_stderr_sv){
                //printf("destroy_easy_fd_stderr_sv: %p, %p\n", c, p);
                SvREFCNT_dec(((p_curl_easy *)p)->fd_stderr_sv);
                ((p_curl_easy *)p)->fd_stderr_sv = NULL;
            }
            if(((p_curl_easy *)p)->headers_slist){
                //printf("destroy_easy_headers_slist: %p, %p\n", (CURL *)THIS(e_http), p);
                curl_slist_free_all(((p_curl_easy *)p)->headers_slist);
                ((p_curl_easy *)p)->headers_slist = NULL;
            }
            ((p_curl_easy *)p)->curle = NULL; // we're about to free ourself (DESTROY SV)
            for(int f=0; f<MAX_CB; f++){
                p_curl_cb *cbe = &((p_curl_easy *)p)->cbs[f];
                //printf("destroy_easy_cb: %d, %p, %p\n", f, cbe->cb, cbe->cd);
                if(cbe->cb)
                    SvREFCNT_dec(cbe->cb);
                if(cbe->cd)
                    SvREFCNT_dec(cbe->cd);
            }
            Safefree(p);
        }
        //printf("after_destroy_easy: %p\n", c);
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
        ST(0) = sv;
        XSRETURN(1);

void U_curl_url_cleanup(SV *u_http=NULL)
    PPCODE:
        dTHX;
        dSP;
        if(!THISSvOK(u_http))
            XSRETURN_UNDEF;
        curl_url_cleanup((CURLU *)THIS(u_http));
        SV *sv = SvRV(u_http);
        sv_setref_pv(sv, NULL, NULL);
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
        ST(0) = sv;
        XSRETURN(1);

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
        ST(0) = sv_2mortal(newSVpv(s, 0));
        XSRETURN(1);

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

void W_curl_ws_meta(SV *ws_http=NULL)
    PPCODE:
        dTHX;
        dSP;
        if(!THISSvOK(ws_http))
            XSRETURN_UNDEF;
        const struct curl_ws_frame *w = curl_ws_meta((CURL *)THIS(ws_http));
        if(!w)
            XSRETURN_UNDEF;
        HV *rh = newHV();
        hv_store(rh, "age"      ,3,newSViv(w->age)       ,0);
        hv_store(rh, "flags"    ,5,newSViv(w->flags)     ,0);
        hv_store(rh, "offset"   ,6,newSViv(w->offset)    ,0);
        hv_store(rh, "bytesleft",9,newSViv(w->bytesleft) ,0);
        ST(0) = sv_2mortal(newRV_inc((SV*)rh));
        XSRETURN(1);

void W_curl_ws_recv(SV *ws_http=NULL, SV *data=&PL_sv_undef, IV max_sz=1, SV *hv_meta=NULL)
    PREINIT:
        int r = 0;
        size_t recv_sz = 0;
    PPCODE:
        dTHX;
        dSP;
        if(!THISSvOK(ws_http))
            XSRETURN_UNDEF;
        const struct curl_ws_frame *w = NULL;
        SV *buf = (SV*)sv_2mortal((SV*)newSV(max_sz));
        SvPOK_only(buf);
        r = curl_ws_recv((CURL *)THIS(ws_http), SvPVX(buf), max_sz, &recv_sz, &w);
        if(r != CURLE_OK)
            XSRETURN_IV(r);
        SvCUR_set(buf, recv_sz);
        if(data){
            if(!SvOK(data)){
                sv_setsv(data, buf);
            } else {
                sv_catsv_nomg(data, buf);
                SvREFCNT_dec(buf);
                buf = NULL;
            }
        }
        if(hv_meta && w){
            HV *rh = (HV*)sv_2mortal((SV*)newHV());
            hv_store(rh, "age"      ,3,newSViv(w->age)       ,0);
            hv_store(rh, "flags"    ,5,newSViv(w->flags)     ,0);
            hv_store(rh, "offset"   ,6,newSViv(w->offset)    ,0);
            hv_store(rh, "bytesleft",9,newSViv(w->bytesleft) ,0);
            sv_setsv(hv_meta, newRV_inc((SV*)rh));
        }
        XSRETURN_IV(r);

void W_curl_ws_send(SV *ws_http=NULL, SV *data=&PL_sv_undef, int ws_code=CURLWS_BINARY)
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
