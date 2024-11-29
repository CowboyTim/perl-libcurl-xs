#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <curl/curl.h>
#include <curl/easy.h>
#include <curl/multi.h>

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

#define THISSvOK(sv) (sv != NULL && SvROK(sv) && SvRV(sv) != &PL_sv_undef && INT2PTR(void *, SvIV(SvRV(sv))) != NULL)
#define THIS(sv)   INT2PTR(void *, SvIV(SvRV(sv)))

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
        XSRETURN_IV(0);
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
        hv_store(rh, "version"       , 7, newSVpv(vi->version       , 0), 0);
        hv_store(rh, "version_num"   , 11, newSViv(vi->version_num)   , 0);
        hv_store(rh, "host"          , 4, newSVpv(vi->host          , 0), 0);
        hv_store(rh, "features"      , 8, newSViv(vi->features      ) , 0);
        hv_store(rh, "ssl_version"   , 11, newSVpv(vi->ssl_version   , 0), 0);
        hv_store(rh, "ssl_version_num", 15, newSViv(vi->ssl_version_num), 0);
        hv_store(rh, "libz_version"  , 12, newSVpv(vi->libz_version  , 0), 0);
        hv_store(rh, "protocols"     , 9, newSVpv((char *)vi->protocols     , 0), 0);
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
        //printf("c: %lld, %p\n", (long long)c, c);
        SV *sv = sv_newmortal();
        SvPOK_only(sv);
        sv_setref_pv(sv, "http::curl::easy", (void *)c);
        SvREADONLY_on(sv);
        XPUSHs(sv);

void L_curl_easy_cleanup(SV *e_http=&PL_sv_undef)
    PPCODE:
        dTHX;
        dSP;
        POPs;
        if(!THISSvOK(e_http))
            XSRETURN_UNDEF;
        //printf("e: %p\n", (CURL *)THIS(e_http));
        sv_setref_pv(e_http, NULL, NULL);
        XSRETURN_UNDEF;

void L_curl_easy_reset(SV *e_http=&PL_sv_undef)
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

void L_curl_easy_setopt(SV *e_http=&PL_sv_undef, int c_opt=0, SV *value=&PL_sv_undef)
    PREINIT:
        int r = 0;
    PPCODE:
        dTHX;
        dSP;
        if(!THISSvOK(e_http))
            XSRETURN_UNDEF;
        if(value == NULL)
            XSRETURN_UNDEF;

        //printf("p: %lld, %p, f: %d & %d\n", (long long)SvIV(SvRV(e_http)), THIS(e_http), c_opt, CURLOPT_URL);
        if(c_opt >= CURLOPTTYPE_LONG && c_opt < CURLOPTTYPE_OBJECTPOINT){
            long _vl = (long)SvIV(value);
            r = curl_easy_setopt((CURL *)THIS(e_http), c_opt, _vl);
        } else if(c_opt >= CURLOPTTYPE_OBJECTPOINT && c_opt < CURLOPTTYPE_FUNCTIONPOINT){
            if(!SvPOK(value))
                XSRETURN_UNDEF;
            char *_vc = (char *)SvPV_nolen(value);
            r = curl_easy_setopt((CURL *)THIS(e_http), c_opt, _vc);
        } else if(c_opt >= CURLOPTTYPE_FUNCTIONPOINT && c_opt < CURLOPTTYPE_OFF_T){
            XSRETURN_UNDEF;
        } else if(c_opt >= CURLOPTTYPE_OFF_T && c_opt < CURLOPTTYPE_BLOB){
            long _vo = (curl_off_t)SvIV(value);
            r = curl_easy_setopt((CURL *)THIS(e_http), c_opt, _vo);
        } else {
            XSRETURN_UNDEF;
        }
        if(r != CURLE_OK)
            XSRETURN_IV(r);
        XSRETURN_IV(0);

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

void L_curl_easy_perform(SV *e_http=&PL_sv_undef)
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

void L_curl_easy_duphandle(SV *e_http=&PL_sv_undef)
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

void L_curl_easy_getinfo(SV *e_http=&PL_sv_undef, int c_info=0)
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

void L_curl_easy_pause(SV *e_http=&PL_sv_undef, int bitmask=0)
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

void L_curl_easy_upkeep(SV *e_http=&PL_sv_undef)
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

void L_curl_easy_send(SV *e_http=&PL_sv_undef, SV *data=&PL_sv_undef, )
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

void L_curl_easy_recv(SV *e_http=&PL_sv_undef, SV *data=&PL_sv_undef, IV max_sz=0)
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

void L_curl_multi_wakeup(SV *m_http=&PL_sv_undef)
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

void L_curl_multi_perform(SV *m_http=&PL_sv_undef, SV *running_handles=NULL)
    PREINIT:
        int r = 0;
        int h = 0;
    PPCODE:
        dTHX;
        dSP;
        if(!THISSvOK(m_http))
            XSRETURN_UNDEF;
        r = curl_multi_perform((CURLM *)THIS(m_http), &h);
        if(r != CURLM_OK)
            XSRETURN_IV(r);
        if(running_handles != NULL && running_handles != &PL_sv_undef){
            sv_setiv(running_handles, h);
        }
        XSRETURN_IV(r);

void L_curl_multi_add_handle(SV *m_http=&PL_sv_undef, SV *e_http=&PL_sv_undef)
    PPCODE:
        dTHX;
        dSP;
        if(!THISSvOK(m_http))
            XSRETURN_UNDEF;
        if(!THISSvOK(e_http))
            XSRETURN_UNDEF;
        int r = curl_multi_add_handle((CURLM *)THIS(m_http), (CURL *)THIS(e_http));
        XSRETURN_IV(r);

void L_curl_multi_remove_handle(SV *m_http=&PL_sv_undef, SV *easy=NULL)
    PPCODE:
        dTHX;
        dSP;
        if(!THISSvOK(m_http))
            XSRETURN_UNDEF;
        if(!easy || !SvROK(easy) || SvRV(easy) == &PL_sv_undef)
            XSRETURN_UNDEF;
        int r = curl_multi_remove_handle((CURLM *)THIS(m_http), (CURL *)THIS(easy));
        XSRETURN_IV(r);

void L_curl_multi_strerror(int code)
    PPCODE:
        dTHX;
        dSP;
        const char *s = curl_multi_strerror(code);
        if(!s)
            XSRETURN_UNDEF;
        XPUSHs(sv_2mortal(newSVpv(s, 0)));

void L_curl_multi_timeout(SV *m_http=&PL_sv_undef, SV *timeout = NULL)
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
        if(timeout != NULL && timeout != &PL_sv_undef){
            sv_setiv(timeout, l);
        }
        XSRETURN_IV(r);

void L_curl_multi_info_read(SV *m_http=&PL_sv_undef)
    PREINIT:
        int r = 0;
    PPCODE:
        dTHX;
        dSP;
        if(!THISSvOK(m_http))
            XSRETURN_UNDEF;
        POPs;
        CURLMsg *m = curl_multi_info_read((CURLM *)THIS(m_http), &r);
        if(!m)
            XSRETURN_UNDEF;
        HV *rh = (HV*)sv_2mortal((SV*)newHV());
        hv_store(rh, "msg"   ,3,newSViv(m->msg)        ,0);
        hv_store(rh, "result",6,newSViv(m->data.result),0);
        XPUSHs(newRV((SV*)rh));

void L_curl_multi_setopt(SV *m_http=&PL_sv_undef, IV c_opt=0, SV *value=NULL)
    PREINIT:
        int r = 0;
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

void L_curl_multi_fdset(SV *m_http=&PL_sv_undef)
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

void L_curl_multi_poll(SV *m_http=&PL_sv_undef, SV *extrafds=&PL_sv_undef, int timeout=0, SV *numfds=&PL_sv_undef)
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
        if(numfds != NULL && numfds != &PL_sv_undef){
            sv_setiv(numfds, nfds);
        }
        XSRETURN_IV(r);
#else
        croak("curl_multi_poll is not supported in this version of libcurl");
#endif

void L_curl_multi_wait(SV *m_http=&PL_sv_undef, SV *extrafds=&PL_sv_undef, int timeout=0, SV *numfds=&PL_sv_undef)
    PREINIT:
        int r = 0;
        int nfds = 0;
    PPCODE:
        dTHX;
        dSP;
        if(!THISSvOK(m_http))
            XSRETURN_UNDEF;
        r = curl_multi_wait((CURLM *)THIS(m_http), NULL, 0, timeout, &nfds);
        if(r != CURLM_OK)
            XSRETURN_IV(r);
        if(numfds != NULL && numfds != &PL_sv_undef){
            sv_setiv(numfds, nfds);
        }
        XSRETURN_IV(r);

void L_curl_multi_get_handles(SV *m_http=&PL_sv_undef)
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
            SV *sv = sv_newmortal();
            sv_setref_pv(sv, "http::curl::easy", (void *)e[i]);
            SvREADONLY_on(sv);
            av_push(av, sv);
        }
        curl_free(e);
        XPUSHs(newRV_noinc((SV *)av));
#else
        croak("curl_multi_get_handles is not supported in this version of libcurl");
#endif


MODULE = utils::curl                PACKAGE = http::curl::multi             PREFIX = M_

VERSIONCHECK: DISABLE
PROTOTYPES: DISABLE

void M_DESTROY(SV *m_http=&PL_sv_undef)
    PPCODE:
        dTHX;
        dSP;
        if(!THISSvOK(m_http))
            XSRETURN_UNDEF;
        //printf("d: %p\n", (CURLM *)THIS(m_http));
        // get all handles and remove them
#if (LIBCURL_VERSION_NUM >= 0x080400)
        CURL **e = curl_multi_get_handles((CURLM *)THIS(m_http));
        if(e){
            for(int i=0; e[i]; i++){
                curl_multi_remove_handle((CURLM *)THIS(m_http), (CURL *)e[i]);
            }
            // don't free the curl_easy handles, as they are still in SV's and will be destroyed by E_DESTROY
        }
#endif
        int r = curl_multi_cleanup((CURLM *)THIS(m_http));
        if(r != CURLM_OK){
            warn("curl_multi_cleanup failed: %s, 0x%p", curl_multi_strerror(r), (CURLM *)THIS(m_http));
            XSRETURN_NO;
        }
        //printf("p: %p\n", (CURLM *)THIS(m_http));
        XSRETURN_YES;

MODULE = utils::curl                PACKAGE = http::curl::easy             PREFIX = E_

VERSIONCHECK: DISABLE
PROTOTYPES: DISABLE

void E_DESTROY(SV *e_http=&PL_sv_undef)
    PPCODE:
        dTHX;
        dSP;
        if(!THISSvOK(e_http))
            XSRETURN_UNDEF;
        printf("destroy_easy: %p\n", (CURL *)THIS(e_http));
        curl_easy_cleanup((CURL *)THIS(e_http));
        XSRETURN_YES;
