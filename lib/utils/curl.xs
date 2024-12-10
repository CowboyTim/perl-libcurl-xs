#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <curl/curl.h>
#include <curl/easy.h>
#include <curl/multi.h>

#define THISSvOK(sv) (sv != NULL && SvROK(sv) && SvOK(SvRV(sv)) && INT2PTR(void *, SvIV(SvRV(sv))) != NULL)
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
    CB_FNMATCH_FUNCTION,
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
    SV *cb;
    SV *cd;
} p_curl_cb;

typedef struct {
    SV *curle;
    p_curl_cb cbs[MAX_CB];
} p_curl_easy;

int cb_setup(CURL *e_http, int c_opt, int c_opt_f, void *cb_f, SV *cb, SV **pt){
    int r = 0;
    void *p = NULL;
    SV **pp = NULL;
    int t = curl_easy_getinfo(e_http, CURLINFO_PRIVATE, &p);
    if(t == CURLE_OK && p){
        pp = &(((p_curl_easy *)p)->cbs[c_opt_f].cb);
        *pt = *pp;
    }
    if(cb){
        r = curl_easy_setopt(e_http, c_opt, cb_f);
        if(r == CURLE_OK)
            *pp = cb;
        else
            *pp = NULL;
    } else {
        *pp = NULL;
        r = curl_easy_setopt(e_http, c_opt, NULL);
    }
    return r;
}

int cd_setup(CURL *e_http, int c_opt, int c_opt_d, SV *value, SV **pt){
    int r = 0;
    void *p = NULL;
    SV **pp = NULL;
    int t = curl_easy_getinfo(e_http, CURLINFO_PRIVATE, &p);
    if(t == CURLE_OK && p){
        pp = &(((p_curl_easy *)p)->cbs[c_opt_d].cd);
        *pt = *pp;
    }
    if(value){
        // we store "value" in the private struct's "cd" for this callback
        *pp = value;
        // we set the userp to the value of "value"
        r = curl_easy_setopt(e_http, c_opt, (void *)value);
        if(r == CURLE_OK)
            *pp = value;
        else
            *pp = NULL;
    } else {
        *pp = NULL;
        r = curl_easy_setopt(e_http, c_opt, NULL);
    }
    return r;
}

int cb_setup_pvt(CURL *e_http, int opt_f, int opt_d, void *cb_f, int cb_indx, SV *cb, SV **ret){
    int r = 0, o = 0, t = 0;
    void *p = NULL;
    SV **pp_c = NULL;
    SV **pp_d = NULL;
    t = curl_easy_getinfo(e_http, CURLINFO_PRIVATE, &p);
    if(t == CURLE_OK && p){
        pp_c = &(((p_curl_easy *)p)->cbs[cb_indx].cb);
        pp_d = &(((p_curl_easy *)p)->cbs[cb_indx].cd);
        *ret = *pp_c;
    }
    if(cb){
        r = curl_easy_setopt(e_http, opt_f, cb_f);
        if(r == CURLE_OK){
            // we set the userp to the vl of private data
            o = curl_easy_setopt(e_http, opt_d, p);
            if(o == CURLE_OK){
                *pp_c = cb;
            } else {
                *pp_c = NULL;
                o = curl_easy_setopt(e_http, opt_f, NULL);
            }
        } else {
            *pp_c = NULL;
        }
    } else {
        *pp_c = NULL;
        r = curl_easy_setopt(e_http, opt_f, NULL);
        if(*pp_d == NULL)
            o = curl_easy_setopt(e_http, opt_d, NULL);
    }
    return r;
}

int cd_setup_pvt(CURL *e_http, int opt_d, int cb_indx, SV *vl, SV **ret){
    int r = 0;
    void *p = NULL;
    SV **pp_d = NULL;
    SV **pp_c = NULL;
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
        }
    } else {
        // we reset this callback's "cd" in the private struct
        *pp_d = NULL;
        if(*pp_c == NULL)
            r = curl_easy_setopt(e_http, opt_d, NULL);
    }
    return r;
}

static int curl_debugfunction_cb(CURL *handle, curl_infotype type, char *data, size_t size, void *userp){
    dTHX;
    dSP;
    void *p = NULL;
    int ri = curl_easy_getinfo(handle, CURLINFO_PRIVATE, &p);
    if(ri != CURLE_OK || !p)
        return 0;
    p_curl_easy *pe = (p_curl_easy *)p;
    SV *cb = (SV *)(pe->cbs[CB_DEBUGFUNCTION].cb);
    if(cb && SvTYPE(cb) != SVt_PVCV)
        return 0;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(newRV(pe->curle));
    XPUSHs(sv_2mortal(newSViv((IV)type)));
    XPUSHs(sv_2mortal(newSVpv(data, size)));
    if(userp && SvOK((SV *)userp))
        XPUSHs((SV *)userp);
    else
        XPUSHs(&PL_sv_undef);
    PUTBACK;
    call_sv(cb, G_DISCARD);
    FREETMPS;
    LEAVE;
    return 0;
}

static int curl_closesocketfunction_cb(void *userp, curl_socket_t item){
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
    XPUSHs(sv_2mortal(newSViv((IV)(int)item)));
    if(cd && SvOK(cd))
        XPUSHs(cd);
    else
        XPUSHs(&PL_sv_undef);
    PUTBACK;
    call_sv(cb, G_DISCARD);
    FREETMPS;
    LEAVE;
    return 0;
}

static int curl_opensocketfunction_cb(void *userp, curlsocktype purpose, struct curl_sockaddr *address){
    dTHX;
    dSP;
    if(!userp)
        return CURL_SOCKET_BAD;
    p_curl_easy *pe = (p_curl_easy *)userp;
    SV *cd = (SV *)(pe->cbs[CB_HSTSREADFUNCTION].cd);
    SV *cb = (SV *)(pe->cbs[CB_HSTSREADFUNCTION].cb);
    if(!cb || SvTYPE(cb) != SVt_PVCV)
        return CURL_SOCKET_BAD;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSViv((IV)purpose)));
    XPUSHs(sv_2mortal(newSViv((IV)address->family)));
    XPUSHs(sv_2mortal(newSViv((IV)address->socktype)));
    XPUSHs(sv_2mortal(newSViv((IV)address->protocol)));
    XPUSHs(sv_2mortal(newSViv((IV)address->addrlen)));
    if(cd && SvOK(cd))
        XPUSHs(cd);
    else
        XPUSHs(&PL_sv_undef);
    PUTBACK;
    int r = call_sv(cb, G_SCALAR);
    SPAGAIN;
    int sock = 0;
    if(r == 1)
        sock = POPi;
    FREETMPS;
    LEAVE;
    if(r == 1)
        return sock;
    return CURL_SOCKET_BAD;
}

static int curl_headerfunction_cb(char *data, size_t size, size_t nmemb, void *userp){
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
    XPUSHs(sv_2mortal(newSVpv(data, size*nmemb)));
    if(cd && SvOK(cd))
        XPUSHs(cd);
    else
        XPUSHs(&PL_sv_undef);
    PUTBACK;
    call_sv(cb, G_DISCARD);
    FREETMPS;
    LEAVE;
    return 0;
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
    XPUSHs(sv_2mortal(newSVpv(buffer, size*nitems)));
    if(cd && SvOK(cd))
        XPUSHs(cd);
    else
        XPUSHs(&PL_sv_undef);
    PUTBACK;
    call_sv(cb, G_DISCARD);
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
    XPUSHs(sv_2mortal(newSVpv(buffer, size*nitems)));
    if(cd && SvOK(cd))
        XPUSHs(cd);
    else
        XPUSHs(&PL_sv_undef);
    PUTBACK;
    call_sv(cb, G_DISCARD);
    FREETMPS;
    LEAVE;
    return 0;
}

static int curl_interleavefunction_cb(void *userp, int mask, int sock){
    dTHX;
    dSP;
    if(!userp)
        return 0;
    p_curl_easy *pe = (p_curl_easy *)userp;
    SV *cd = (SV *)(pe->cbs[CB_INTERLEAVEFUNCTION].cd);
    SV *cb = (SV *)(pe->cbs[CB_INTERLEAVEFUNCTION].cb);
    if(!cb || SvTYPE(cb) != SVt_PVCV)
        return 0;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSViv(mask)));
    XPUSHs(sv_2mortal(newSViv(sock)));
    if(cd && SvOK(cd))
        XPUSHs(cd);
    else
        XPUSHs(&PL_sv_undef);
    PUTBACK;
    call_sv(cb, G_DISCARD);
    FREETMPS;
    LEAVE;
    return 0;
}

static int curl_ioctlfunction_cb(CURL *handle, int cmd, void *clientp){
    dTHX;
    dSP;
    void *p = NULL;
    int ri = curl_easy_getinfo(handle, CURLINFO_PRIVATE, &p);
    if(ri != CURLE_OK || !p)
        return CURLIOE_OK; // consider OK?
    p_curl_easy *pe = (p_curl_easy *)p;
    SV *cb = (SV *)(pe->cbs[CB_IOCTLFUNCTION].cb);
    if(cb && SvTYPE(cb) != SVt_PVCV)
        return CURLIOE_OK; // consider OK?
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(newRV(pe->curle));
    XPUSHs(sv_2mortal(newSViv(cmd)));
    if(clientp && SvOK((SV *)clientp))
        XPUSHs((SV *)clientp);
    else
        XPUSHs(&PL_sv_undef);
    PUTBACK;
    int r = call_sv(cb, G_SCALAR);
    SPAGAIN;
    int res = 0;
    if(r == 1)
        res = POPi;
    FREETMPS;
    LEAVE;
    return res;
}

static int curl_fnmatchfunction_cb(void *userp, const char *pattern, const char *string){
    dTHX;
    dSP;
    if(!userp)
        return 0;
    p_curl_easy *pe = (p_curl_easy *)userp;
    SV *cd = (SV *)(pe->cbs[CB_FNMATCH_FUNCTION].cd);
    SV *cb = (SV *)(pe->cbs[CB_FNMATCH_FUNCTION].cb);
    if(!cb || SvTYPE(cb) != SVt_PVCV)
        return 0;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpv(pattern, 0)));
    XPUSHs(sv_2mortal(newSVpv(string, 0)));
    if(cd && SvOK(cd))
        XPUSHs(cd);
    else
        XPUSHs(&PL_sv_undef);
    PUTBACK;
    int r = call_sv(cb, G_SCALAR);
    SPAGAIN;
    int res = 0;
    if(r == 1)
        res = POPi;
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
    XPUSHs(sv_2mortal(newSVpv(conn_primary_ip, 0)));
    XPUSHs(sv_2mortal(newSVpv(conn_local_ip, 0)));
    XPUSHs(sv_2mortal(newSViv(conn_primary_port)));
    XPUSHs(sv_2mortal(newSViv(conn_local_port)));
    if(cd && SvOK(cd))
        XPUSHs(cd);
    else
        XPUSHs(&PL_sv_undef);
    PUTBACK;
    int r = call_sv(cb, G_SCALAR);
    SPAGAIN;
    int res = 0;
    if(r == 1)
        res = POPi;
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
    XPUSHs(sv_2mortal(newSVnv(dltotal)));
    XPUSHs(sv_2mortal(newSVnv(dlnow)));
    XPUSHs(sv_2mortal(newSVnv(ultotal)));
    XPUSHs(sv_2mortal(newSVnv(ulnow)));
    if(cd && SvOK(cd))
        XPUSHs(cd);
    else
        XPUSHs(&PL_sv_undef);
    PUTBACK;
    int r = call_sv(cb, G_SCALAR);
    SPAGAIN;
    int res = 0;
    if(r == 1)
        res = POPi;
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
    XPUSHs(newRV(pe->curle));
    XPUSHs(sv_2mortal(newSViv(size*nitems)));
    if(cd && SvOK(cd))
        XPUSHs(cd);
    else
        XPUSHs(&PL_sv_undef);
    PUTBACK;
    int r = call_sv(cb, G_SCALAR);
    SPAGAIN;
    if(!r){
        FREETMPS;
        LEAVE;
        return 0;
    }
    SV *sv = POPs;
    if(!SvPOK(sv)){
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
    XPUSHs(newRV(pe->curle));
    XPUSHs(sv_2mortal(newSVpv(buffer, size*nitems)));
    if(cd && SvOK(cd))
        XPUSHs(cd);
    else
        XPUSHs(&PL_sv_undef);
    PUTBACK;
    int r = call_sv(cb, G_SCALAR);
    SPAGAIN;
    int res = 0;
    if(r >= 1)
        res = POPi;
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
    XPUSHs(sv_2mortal(newSViv(PTR2IV(resolver_state))));
    if(cd && SvOK(cd))
        XPUSHs(cd);
    else
        XPUSHs(&PL_sv_undef);
    PUTBACK;
    int r = call_sv(cb, G_SCALAR);
    SPAGAIN;
    int res = 0;
    if(r == 1)
        res = POPi;
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
    XPUSHs(sv_2mortal(newSViv((IV)offset)));
    XPUSHs(sv_2mortal(newSViv((IV)origin)));
    if(cd && SvOK(cd))
        XPUSHs(cd);
    else
        XPUSHs(&PL_sv_undef);
    PUTBACK;
    int r = call_sv(cb, G_SCALAR);
    SPAGAIN;
    int res = 0;
    if(r == 1)
        res = POPi;
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
    XPUSHs(sv_2mortal(newSViv(PTR2IV(curlfd))));
    XPUSHs(sv_2mortal(newSViv(PTR2IV(purpose))));
    if(cd && SvOK(cd))
        XPUSHs(cd);
    else
        XPUSHs(&PL_sv_undef);
    PUTBACK;
    int r = call_sv(cb, G_SCALAR);
    SPAGAIN;
    int res = 0;
    if(r == 1)
        res = POPi;
    FREETMPS;
    LEAVE;
    return res;
}

static int curl_ssl_ctx_function_cb(CURL *handle, void *sslctx, void *userp){
    dTHX;
    dSP;
    void *p = NULL;
    int ri = curl_easy_getinfo(handle, CURLINFO_PRIVATE, &p);
    if(ri != CURLE_OK || !p)
        return 0;
    p_curl_easy *pe = (p_curl_easy *)p;
    SV *cb = (SV *)(pe->cbs[CB_SSL_CTX_FUNCTION].cb);
    if(cb && SvTYPE(cb) != SVt_PVCV)
        return 0;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSViv(PTR2IV(sslctx))));
    if(userp && SvOK((SV *)userp))
        XPUSHs((SV *)userp);
    else
        XPUSHs(&PL_sv_undef);
    PUTBACK;
    int r = call_sv(cb, G_SCALAR);
    SPAGAIN;
    int res = 0;
    if(r == 1)
        res = POPi;
    FREETMPS;
    LEAVE;
    return res;
}

static int curl_ssh_keyfunction_cb(CURL *handle, const struct curl_khkey *knownkey, const struct curl_khkey *foundkey, int khmatch, void *userp){
    dTHX;
    dSP;
    void *p = NULL;
    int ri = curl_easy_getinfo(handle, CURLINFO_PRIVATE, &p);
    if(ri != CURLE_OK || !p)
        return 0;
    p_curl_easy *pe = (p_curl_easy *)p;
    SV *cb = (SV *)(pe->cbs[CB_SSH_KEYFUNCTION].cb);
    if(cb && SvTYPE(cb) != SVt_PVCV)
        return 0;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    if(knownkey->key)
        if(knownkey->len)
            XPUSHs(sv_2mortal(newSVpv(knownkey->key, knownkey->len)));
        else
            XPUSHs(sv_2mortal(newSVpv(knownkey->key, 0)));
    else
        XPUSHs(&PL_sv_undef);
    if(foundkey->key)
        if(foundkey->len)
            XPUSHs(sv_2mortal(newSVpv(foundkey->key, foundkey->len)));
        else
            XPUSHs(sv_2mortal(newSVpv(foundkey->key, 0)));
    else
        XPUSHs(&PL_sv_undef);
    XPUSHs(sv_2mortal(newSViv((int)(IV)khmatch)));
    if(userp && SvOK((SV *)userp))
        XPUSHs((SV *)userp);
    else
        XPUSHs(&PL_sv_undef);
    PUTBACK;
    int r = call_sv(cb, G_SCALAR);
    SPAGAIN;
    int res = 0;
    if(r == 1)
        res = POPi;
    FREETMPS;
    LEAVE;
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
    XPUSHs(sv_2mortal(newSVpv(data, size*nmemb)));
    if(cd && SvOK(cd))
        XPUSHs(cd);
    else
        XPUSHs(&PL_sv_undef);
    PUTBACK;
    call_sv(cb, G_DISCARD);
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
    XPUSHs(sv_2mortal(newSViv((IV)dltotal)));
    XPUSHs(sv_2mortal(newSViv((IV)dlnow)));
    XPUSHs(sv_2mortal(newSViv((IV)ultotal)));
    XPUSHs(sv_2mortal(newSViv((IV)ulnow)));
    if(cd && SvOK(cd))
        XPUSHs(cd);
    else
        XPUSHs(&PL_sv_undef);
    PUTBACK;
    int r = call_sv(cb, G_SCALAR);
    SPAGAIN;
    int res = 0;
    if(r == 1)
        res = POPi;
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
        if(!ptr)
            XSRETURN_IV(CURLE_OUT_OF_MEMORY);
        //printf("c: %p, %p\n", c, ptr);
        ((p_curl_easy *)ptr)->curle = SvRV(sv); // no need to increase refcount
        int t = curl_easy_setopt(c, CURLOPT_PRIVATE, ptr);
        if(t != CURLE_OK){
            Safefree(ptr);
            curl_easy_cleanup(c);
            XSRETURN_IV(t);
        }

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
        struct curl_slist *_vs = NULL;
        AV *av = NULL;
    PPCODE:
        dTHX;
        dSP;
        if(!THISSvOK(e_http))
            XSRETURN_UNDEF;

        if(c_opt >= CURLOPTTYPE_LONG && c_opt < CURLOPTTYPE_OBJECTPOINT
            || c_opt == CURLOPTTYPE_VALUES){
            long _vl = (long)SvIV(value);
            r = curl_easy_setopt((CURL *)THIS(e_http), c_opt, _vl);
        } else if(c_opt >= CURLOPTTYPE_OBJECTPOINT && c_opt < CURLOPTTYPE_FUNCTIONPOINT){
            int cb_indx = -1, cb_handle = 1, f = 0;
            SV *p = NULL;
            SV *dt = NULL;
            if(value && SvOK(value))
                dt = value;
            switch(c_opt){
                case CURLOPT_HTTPHEADER:
                case CURLOPT_QUOTE:
                case CURLOPT_POSTQUOTE:
                case CURLOPT_TELNETOPTIONS:
                case CURLOPT_PREQUOTE:
                case CURLOPT_HTTP200ALIASES:
                case CURLOPT_MAIL_RCPT:
                case CURLOPT_RESOLVE:
                case CURLOPT_PROXYHEADER:
                case CURLOPT_CONNECT_TO:
                    av = (AV *)SvRV(dt);
                    for(int i=0; i<=av_len(av); i++){
                        SV **sv = av_fetch(av, i, 0);
                        if(sv && SvPOK(*sv)){
                            _vs = curl_slist_append(_vs, SvPV_nolen(*sv));
                        }
                    }
                    r = curl_easy_setopt((CURL *)THIS(e_http), c_opt, _vs);
                    f = 1;
                    break;
                case CURLOPT_DEBUGDATA:
                    cb_indx = CB_DEBUGFUNCTION;
                    cb_handle = 1;
                    break;
                case CURLOPT_IOCTLDATA:
                    cb_indx = CB_IOCTLFUNCTION;
                    cb_handle = 1;
                    break;
                case CURLOPT_SSH_KEYDATA:
                    cb_indx = CB_SSH_KEYFUNCTION;
                    cb_handle = 1;
                    break;
                case CURLOPT_SSL_CTX_DATA:
                    cb_indx = CB_SSL_CTX_FUNCTION;
                    cb_handle = 1;
                    break;
                case CURLOPT_READDATA:
                    cb_indx = CB_READFUNCTION;
                    cb_handle = 0;
                    break;
                case CURLOPT_WRITEDATA:
                    cb_indx = CB_WRITEFUNCTION;
                    cb_handle = 0;
                    break;
                case CURLOPT_FNMATCH_DATA:
                    cb_indx = CB_FNMATCH_FUNCTION;
                    cb_handle = 0;
                    break;
                case CURLOPT_PREREQDATA:
                    cb_indx = CB_PREREQFUNCTION;
                    cb_handle = 0;
                    break;
                case CURLOPT_SEEKDATA:
                    cb_indx = CB_SEEKFUNCTION;
                    cb_handle = 0;
                    break;
                case CURLOPT_SOCKOPTDATA:
                    cb_indx = CB_SOCKOPTFUNCTION;
                    cb_handle = 0;
                    break;
                case CURLOPT_CLOSESOCKETDATA:
                    cb_indx = CB_CLOSESOCKETFUNCTION;
                    cb_handle = 0;
                    break;
                case CURLOPT_OPENSOCKETDATA:
                    cb_indx = CB_OPENSOCKETFUNCTION;
                    cb_handle = 0;
                    break;
                case CURLOPT_HEADERDATA:
                    cb_indx = CB_HEADERFUNCTION;
                    cb_handle = 0;
                    break;
                case CURLOPT_HSTSREADDATA:
                    cb_indx = CB_HSTSREADFUNCTION;
                    cb_handle = 0;
                    break;
                case CURLOPT_HSTSWRITEDATA:
                    cb_indx = CB_HSTSWRITEFUNCTION;
                    cb_handle = 0;
                    break;
                case CURLOPT_INTERLEAVEDATA:
                    cb_indx = CB_INTERLEAVEFUNCTION;
                    cb_handle = 0;
                    break;
                case CURLOPT_RESOLVER_START_DATA:
                    cb_indx = CB_RESOLVER_START_FUNCTION;
                    cb_handle = 0;
                    break;
                case CURLOPT_TRAILERDATA:
                    cb_indx = CB_TRAILERFUNCTION;
                    cb_handle = 0;
                    break;
                case CURLOPT_XFERINFODATA:
                    cb_indx = CB_XFERINFOFUNCTION;
                    cb_handle = 0;
                    break;
                default:
                    if(!SvPOK(dt))
                        XSRETURN_IV(CURLE_BAD_FUNCTION_ARGUMENT);
                    char *_vc = (char *)SvPV_nolen(dt);
                    r = curl_easy_setopt((CURL *)THIS(e_http), c_opt, _vc);
                    f = 1;
                    break;
            }
            if(!f){
                if(cb_indx != -1){
                    if(cb_handle){
                        r = cd_setup((CURL *)THIS(e_http), c_opt, cb_indx, dt, &p);
                    } else {
                        r = cd_setup_pvt((CURL *)THIS(e_http), c_opt, cb_indx, dt, &p);
                    }
                    if(r == CURLE_OK){
                        if(dt)
                            SvREFCNT_inc(dt);
                    }
                    if(p)
                        SvREFCNT_dec(p);
                } else {
                    XSRETURN_IV(CURLE_BAD_FUNCTION_ARGUMENT);
                }
            }
        } else if(c_opt >= CURLOPTTYPE_FUNCTIONPOINT && c_opt < CURLOPTTYPE_OFF_T){
            int cb_indx = -1, cd_indx = -1, t = -1, cb_handle = 1;
            // NULL clears the FUNCTION/DATA combination
            SV *cb = NULL;
            SV *p = NULL;
            void *cb_func = NULL;
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
                case CURLOPT_DEBUGFUNCTION:
                    cb_indx = CB_DEBUGFUNCTION;
                    cb_func = curl_debugfunction_cb;
                    cb_handle = 1;
                    break;
                case CURLOPT_IOCTLFUNCTION:
                    cb_indx = CB_IOCTLFUNCTION;
                    cb_func = curl_ioctlfunction_cb;
                    cb_handle = 1;
                    break;
                case CURLOPT_SSL_CTX_FUNCTION:
                    cb_indx = CB_SSL_CTX_FUNCTION;
                    cb_func = curl_ssl_ctx_function_cb;
                    cb_handle = 1;
                    break;
                case CURLOPT_SSH_KEYFUNCTION:
                    cb_indx = CB_SSH_KEYFUNCTION;
                    cb_func = curl_ssh_keyfunction_cb;
                    cb_handle = 1;
                    break;
                case CURLOPT_READFUNCTION:
                    cb_indx = CB_READFUNCTION;
                    cd_indx = CURLOPT_READDATA;
                    cb_func = curl_readfunction_cb;
                    cb_handle = 0;
                    break;
                case CURLOPT_WRITEFUNCTION:
                    cb_indx = CB_WRITEFUNCTION;
                    cd_indx = CURLOPT_WRITEDATA;
                    cb_func = curl_writefunction_cb;
                    cb_handle = 0;
                    break;
                case CURLOPT_FNMATCH_FUNCTION:
                    cb_indx = CB_FNMATCH_FUNCTION;
                    cd_indx = CURLOPT_FNMATCH_DATA;
                    cb_func = curl_fnmatchfunction_cb;
                    cb_handle = 0;
                    break;
                case CURLOPT_PREREQFUNCTION:
                    cb_indx = CB_PREREQFUNCTION;
                    cd_indx = CURLOPT_PREREQDATA;
                    cb_func = curl_prereqfunction_cb;
                    cb_handle = 0;
                    break;
                case CURLOPT_SEEKFUNCTION:
                    cb_indx = CB_SEEKFUNCTION;
                    cd_indx = CURLOPT_SEEKDATA;
                    cb_func = curl_seekfunction_cb;
                    cb_handle = 0;
                    break;
                case CURLOPT_SOCKOPTFUNCTION:
                    cb_indx = CB_SOCKOPTFUNCTION;
                    cd_indx = CURLOPT_SOCKOPTDATA;
                    cb_func = curl_sockoptfunction_cb;
                    cb_handle = 0;
                    break;
                case CURLOPT_CLOSESOCKETFUNCTION:
                    cb_indx = CB_CLOSESOCKETFUNCTION;
                    cd_indx = CURLOPT_CLOSESOCKETDATA;
                    cb_func = curl_closesocketfunction_cb;
                    cb_handle = 0;
                    break;
                case CURLOPT_OPENSOCKETFUNCTION:
                    cb_indx = CB_OPENSOCKETFUNCTION;
                    cd_indx = CURLOPT_OPENSOCKETDATA;
                    cb_func = curl_opensocketfunction_cb;
                    cb_handle = 0;
                    break;
                case CURLOPT_HEADERFUNCTION:
                    cb_indx = CB_HEADERFUNCTION;
                    cd_indx = CURLOPT_HEADERDATA;
                    cb_func = curl_headerfunction_cb;
                    cb_handle = 0;
                    break;
                case CURLOPT_HSTSREADFUNCTION:
                    cb_indx = CB_HSTSREADFUNCTION;
                    cd_indx = CURLOPT_HSTSREADDATA;
                    cb_func = curl_hstsreadfunction_cb;
                    cb_handle = 0;
                    break;
                case CURLOPT_HSTSWRITEFUNCTION:
                    cb_indx = CB_HSTSWRITEFUNCTION;
                    cd_indx = CURLOPT_HSTSWRITEDATA;
                    cb_func = curl_hstswritefunction_cb;
                    cb_handle = 0;
                    break;
                case CURLOPT_INTERLEAVEFUNCTION:
                    cb_indx = CB_INTERLEAVEFUNCTION;
                    cd_indx = CURLOPT_INTERLEAVEDATA;
                    cb_func = curl_interleavefunction_cb;
                    cb_handle = 0;
                    break;
                case CURLOPT_RESOLVER_START_FUNCTION:
                    cb_indx = CB_RESOLVER_START_FUNCTION;
                    cd_indx = CURLOPT_RESOLVER_START_DATA;
                    cb_func = curl_resolver_start_function_cb;
                    cb_handle = 0;
                    break;
                case CURLOPT_TRAILERFUNCTION:
                    cb_indx = CB_TRAILERFUNCTION;
                    cd_indx = CURLOPT_TRAILERDATA;
                    cb_func = curl_trailerfunction_cb;
                    cb_handle = 0;
                    break;
                case CURLOPT_XFERINFOFUNCTION:
                    cb_indx = CB_XFERINFOFUNCTION;
                    cd_indx = CURLOPT_XFERINFODATA;
                    cb_func = curl_xferinfofunction_cb;
                    cb_handle = 0;
                    break;
                default:
                    cb_indx = -1;
                    XSRETURN_IV(CURLE_BAD_FUNCTION_ARGUMENT);
                    break;
            }
            if(cb_handle){
                r = cb_setup((CURL *)THIS(e_http), c_opt, cb_indx, cb_func, cb, &p);
            } else {
                r = cb_setup_pvt((CURL *)THIS(e_http), c_opt, cd_indx, cb_func, cb_indx, cb, &p);
            }
            // first increase refcount, then decrease the old one, else we
            // might GC the object while we are just reusing the same var
            if(r == CURLE_OK){
                if(cb)
                    SvREFCNT_inc(cb);
            }
            if(p)
                SvREFCNT_dec(p);
        } else if(c_opt >= CURLOPTTYPE_OFF_T && c_opt < CURLOPTTYPE_BLOB){
            long _vo = (curl_off_t)SvIV(value);
        //printf("p3: %lld, %p, f: %d & %d\n", (long long)SvIV(SvRV(e_http)), THIS(e_http), c_opt, CURLOPT_URL);
            r = curl_easy_setopt((CURL *)THIS(e_http), c_opt, _vo);
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
        if(!ptr)
            XSRETURN_IV(CURLE_OUT_OF_MEMORY);
        int d = curl_easy_setopt(c, CURLOPT_PRIVATE, ptr);
        if(d != CURLE_OK){
            Safefree(ptr);
            curl_easy_cleanup(c);
            XSRETURN_IV(d);
        }
        ((p_curl_easy *)ptr)->curle = SvRV(sv); // no need to increase refcount
        //printf("d: %lld, %p, %p\n", (long long)c, c, ptr);

        // fetch from the original handle the FUNCTION opts
        void *p = NULL;
        int r = curl_easy_getinfo((CURL *)THIS(e_http), CURLINFO_PRIVATE, &p);
        if(r == CURLE_OK && p){
            for(int f=CB_FIRST; f<CB_LAST; f++){
                SvREFCNT_inc((SV *)((p_curl_easy *)p)->cbs[f].cb);
                ((p_curl_easy *)ptr)->cbs[f].cb = ((p_curl_easy *)p)->cbs[f].cb;
                SvREFCNT_inc((SV *)((p_curl_easy *)p)->cbs[f].cd);
                ((p_curl_easy *)ptr)->cbs[f].cd = ((p_curl_easy *)p)->cbs[f].cd;
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
        if(max_sz == 0)
            XSRETURN_IV(0);
        SV *buf = (SV*)sv_2mortal(newSV(max_sz));
        SvPOK_only(buf);
        r = curl_easy_recv((CURL *)THIS(e_http), SvPVX(buf), max_sz, &recv_sz);
        if(r != CURLE_OK)
            XSRETURN_IV(r);
        SvCUR_set(buf, recv_sz);
        if(data){
            if(!SvOK(data))
                sv_setsv(data, buf);
            else
                sv_catpvn(data, SvPVX(buf), recv_sz);
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
        void *p = NULL;
        int rp = curl_easy_getinfo((CURL *)THIS(e_http), CURLINFO_PRIVATE, &p);
        int r = curl_multi_remove_handle((CURLM *)THIS(m_http), (CURL *)THIS(e_http));
        if(r != CURLM_OK)
            XSRETURN_IV(r);
        if(rp == CURLE_OK && p && ((p_curl_easy *)p)->curle == SvRV(e_http)){
            if(SvREFCNT(SvRV(e_http)) > 1)
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
            SvREFCNT_inc(((p_curl_easy *)p)->curle);
            av_push(av, newRV(((p_curl_easy *)p)->curle));
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
        CURL **e = curl_multi_get_handles((CURLM *)THIS(m_http));
        if(e){
            for(int i=0; e[i]; i++){
                curl_multi_remove_handle((CURLM *)THIS(m_http), (CURL *)e[i]);
                void *p = NULL;
                int r = curl_easy_getinfo((CURL *)e[i], CURLINFO_PRIVATE, &p);
                if(r == CURLE_OK && p && ((p_curl_easy *)p)->curle){
                    SvREFCNT_dec(((p_curl_easy *)p)->curle);
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
                SvREFCNT_dec((SV *)((p_curl_easy *)p)->cbs[f].cb);
                SvREFCNT_dec((SV *)((p_curl_easy *)p)->cbs[f].cd);
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

void W_curl_ws_meta(SV *ws_http=NULL)
    PPCODE:
        dTHX;
        dSP;
        if(!THISSvOK(ws_http))
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
            if(!SvOK(data))
                sv_setsv(data, buf);
            else
                sv_catsv_nomg(data, buf);
        }
        if(hv_meta && w){
            HV *rh = (HV*)sv_2mortal((SV*)newHV());
            hv_store(rh, "age"      ,3,newSViv(w->age)       ,0);
            hv_store(rh, "flags"    ,5,newSViv(w->flags)     ,0);
            hv_store(rh, "offset"   ,6,newSViv(w->offset)    ,0);
            hv_store(rh, "bytesleft",9,newSViv(w->bytesleft) ,0);
            sv_setsv(hv_meta, newRV((SV*)rh));
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
