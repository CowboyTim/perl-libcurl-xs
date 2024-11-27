#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <curl/curl.h>
#include <curl/easy.h>
#include <curl/multi.h>

MODULE = utils::curl                PACKAGE = http

BOOT:
{
        HV *stash = gv_stashpv("http", 0);
        newCONSTSUB(stash, "CURLPAUSE_RECV"             , newSViv(CURLPAUSE_RECV));
        newCONSTSUB(stash, "CURLPAUSE_RECV_CONT"        , newSViv(CURLPAUSE_RECV_CONT));
        newCONSTSUB(stash, "CURLPAUSE_SEND"             , newSViv(CURLPAUSE_SEND));
        newCONSTSUB(stash, "CURLPAUSE_SEND_CONT"        , newSViv(CURLPAUSE_SEND_CONT));
        newCONSTSUB(stash, "CURLPAUSE_ALL"              , newSViv(CURLPAUSE_ALL));
        newCONSTSUB(stash, "CURLPAUSE_CONT"             , newSViv(CURLPAUSE_CONT));
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
        newCONSTSUB(stash, "CURL_PUSH_ERROROUT"         , newSViv(CURL_PUSH_ERROROUT));
}

void curl_easy_init()
    PPCODE:
        dTHX;
        dSP;
        CURL *c = curl_easy_init();
        if(!c)
            XSRETURN_NO;
        //printf("c: %p\n", c);
        SV *sv = sv_newmortal();
        sv_setref_pv(sv, "http::curl::easy", (void *)c);
        SvREADONLY_on(sv);
        XPUSHs(sv);

void curl_easy_cleanup(SV *http=NULL)
    PPCODE:
        dTHX;
        dSP;
        if(!http || !SvROK(http) || SvRV(http) == &PL_sv_undef)
            XSRETURN_UNDEF;
        curl_easy_cleanup((CURL *)SvIV(SvRV(http)));
        SvRV(http) = &PL_sv_undef;
        XSRETURN_UNDEF;

void curl_easy_reset(SV *http=NULL)
    PPCODE:
        dTHX;
        dSP;
        if(!http || !SvROK(http) || SvRV(http) == &PL_sv_undef)
            XSRETURN_UNDEF;
        curl_easy_reset((CURL *)SvIV(SvRV(http)));
        XSRETURN_UNDEF;

void curl_easy_strerror(int code)
    PPCODE:
        dTHX;
        dSP;
        const char *s = curl_easy_strerror(code);
        if(!s)
            XSRETURN_UNDEF;
        XPUSHs(sv_2mortal(newSVpv(s, 0)));

void curl_easy_setopt(SV *http=NULL, IV c_opt=0, SV *value=NULL)
    PREINIT:
        int r = 0;
        void *_v = NULL;
    PPCODE:
        dTHX;
        dSP;
        if(!http || !SvROK(http) || SvRV(http) == &PL_sv_undef)
            XSRETURN_UNDEF;
        if(value == NULL)
            XSRETURN_UNDEF;

        //printf("p: %p, f: %d & %d\n", SvIV(SvRV(http)), c_opt, CURLOPT_URL);
        if(c_opt >= CURLOPTTYPE_LONG && c_opt < CURLOPTTYPE_OBJECTPOINT){
            _v = (long *)SvIV(value);
        } else if(c_opt >= CURLOPTTYPE_OBJECTPOINT && c_opt < CURLOPTTYPE_FUNCTIONPOINT){
            if(!SvPOK(value))
                XSRETURN_UNDEF;
            _v = (char *)SvPV_nolen(value);
        } else if(c_opt >= CURLOPTTYPE_FUNCTIONPOINT && c_opt < CURLOPTTYPE_OFF_T){
            XSRETURN_UNDEF;
        } else if(c_opt >= CURLOPTTYPE_OFF_T && c_opt < CURLOPTTYPE_BLOB){
            _v = (curl_off_t *)SvIV(value);
        } else {
            XSRETURN_UNDEF;
        }
        r = curl_easy_setopt((CURL *)SvIV(SvRV(http)), c_opt, _v);
        if(r != CURLE_OK)
            XSRETURN_IV(r);
        XSRETURN_IV(0);

void curl_easy_option_by_name(...)
    PPCODE:
        dTHX;
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

void curl_easy_getinfo_by_id(...)
    PPCODE:
        dTHX;
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

void curl_easy_perform(SV *http=NULL)
    PREINIT:
        int r;
    PPCODE:
        dTHX;
        dSP;
        if(!http || !SvROK(http) || SvRV(http) == &PL_sv_undef)
            XSRETURN_UNDEF;
        r = curl_easy_perform((CURL *)SvIV(SvRV(http)));
        if(r != CURLE_OK)
            XSRETURN_IV(r);
        XSRETURN_IV(0);

void curl_easy_duphandle(SV *http=NULL)
    PPCODE:
        dTHX;
        dSP;
        if(!http || !SvROK(http) || SvRV(http) == &PL_sv_undef)
            XSRETURN_UNDEF;
        CURL *c = curl_easy_duphandle((CURL *)SvIV(SvRV(http)));
        if(!c)
            XSRETURN_NO;
        SV *sv = sv_newmortal();
        sv_setref_pv(sv, "http::curl::easy", (void *)c);
        SvREADONLY_on(sv);
        XPUSHs(sv);

void curl_easy_escape(...)
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

void curl_easy_unescape(...)
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

void curl_easy_getinfo(SV *http=NULL, int c_info=0)
    PREINIT:
        long l = 0;
        curl_off_t o = 0;
        int r = 0;
        double d = 0;
        char *s = NULL;
    PPCODE:
        dTHX;
        dSP;
        if(!http || !SvROK(http) || SvRV(http) == &PL_sv_undef)
            XSRETURN_UNDEF;
        if(c_info == 0)
            XSRETURN_UNDEF;
        if(c_info >= CURLINFO_STRING && c_info < CURLINFO_LONG){
            r = curl_easy_getinfo((CURL *)SvIV(SvRV(http)), c_info, &s);
            if(r != CURLE_OK)
                XSRETURN_UNDEF;
            ST(0) = sv_2mortal(newSVpv(s, 0));
            XSRETURN(1);
        } else if(c_info >= CURLINFO_LONG && c_info < CURLINFO_DOUBLE){
            r = curl_easy_getinfo((CURL *)SvIV(SvRV(http)), c_info, &l);
            if(r != CURLE_OK)
                XSRETURN_UNDEF;
            XSRETURN_IV(l);
        } else if(c_info >= CURLINFO_DOUBLE && c_info < CURLINFO_SLIST){
            r = curl_easy_getinfo((CURL *)SvIV(SvRV(http)), c_info, &d);
            if(r != CURLE_OK)
                XSRETURN_UNDEF;
            XSRETURN_NV(d);
        } else if(c_info >= CURLINFO_PTR && c_info < CURLINFO_SOCKET){
            r = curl_easy_getinfo((CURL *)SvIV(SvRV(http)), c_info, &l);
            if(r != CURLE_OK)
                XSRETURN_UNDEF;
            XSRETURN_IV(l);
        } else if(c_info >= CURLINFO_SOCKET && c_info < CURLINFO_OFF_T){
            r = curl_easy_getinfo((CURL *)SvIV(SvRV(http)), c_info, &l);
            if(r != CURLE_OK)
                XSRETURN_UNDEF;
            XSRETURN_IV(l);
        } else if(c_info >= CURLINFO_OFF_T){
            r = curl_easy_getinfo((CURL *)SvIV(SvRV(http)), c_info, &o);
            if(r != CURLE_OK)
                XSRETURN_UNDEF;
            XSRETURN_IV((IV)((long)o));
        } else {
            XSRETURN_UNDEF;
        }

void curl_easy_pause(SV *http=NULL, int bitmask=0)
    PREINIT:
        int r = 0;
    PPCODE:
        dTHX;
        dSP;
        if(!http || !SvROK(http) || SvRV(http) == &PL_sv_undef)
            XSRETURN_UNDEF;
        r = curl_easy_pause((CURL *)SvIV(SvRV(http)), bitmask);
        if(r != CURLE_OK)
            XSRETURN_IV(r);
        XSRETURN_IV(0);

void curl_easy_upkeep(SV *http=NULL)
    PREINIT:
        int r = 0;
    PPCODE:
        dTHX;
        dSP;
        if(!http || !SvROK(http) || SvRV(http) == &PL_sv_undef)
            XSRETURN_UNDEF;
        r = curl_easy_upkeep((CURL *)SvIV(SvRV(http)));
        if(r != CURLE_OK)
            XSRETURN_IV(r);
        XSRETURN_IV(0);

void curl_easy_send(SV *http=(SV*)&PL_sv_undef, SV *data=(SV*)&PL_sv_undef, )
    PREINIT:
        int r = 0;
        size_t sent_sz = 0;
    PPCODE:
        dTHX;
        dSP;
        if(!http || !SvROK(http) || SvRV(http) == &PL_sv_undef)
            XSRETURN_UNDEF;
        if(!data || !SvPOK(data))
            XSRETURN_UNDEF;
        r = curl_easy_send((CURL *)SvIV(SvRV(http)), SvPV_nolen(data), SvCUR(data), &sent_sz);
        if(r != CURLE_OK)
            XSRETURN_IV(r);
        //printf("data: %s %d\n", SvPV_nolen(data), sent_sz);
        XSRETURN_IV(0);

void curl_easy_recv(SV *http=(SV*)&PL_sv_undef, SV *data=(SV*)&PL_sv_undef, IV max_sz=0)
    PREINIT:
        int r = 0;
        size_t recv_sz = 0;
    PPCODE:
        dTHX;
        dSP;
        if(!http || !SvROK(http) || SvRV(http) == &PL_sv_undef)
            XSRETURN_UNDEF;
        if(!data || !SvPOK(data) || SvRV(data) == &PL_sv_undef)
            XSRETURN_UNDEF;
        if(max_sz == 0)
            XSRETURN_IV(0);
        SV *buf = newSV(max_sz);
        SvPOK_only(buf);
        r = curl_easy_recv((CURL *)SvIV(SvRV(http)), SvPVX(buf), max_sz, &recv_sz);
        if(r != CURLE_OK)
            XSRETURN_IV(r);
        buf = sv_2mortal(buf);
        SvCUR_set(buf, recv_sz);
        sv_catsv_nomg(data, buf);
        XSRETURN_IV(0);

void curl_multi_init()
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

void curl_mutli_cleanup(SV *http=NULL)
    PREINIT:
        int r = 0;
    PPCODE:
        dTHX;
        dSP;
        if(!http || !SvROK(http) || SvRV(http) == &PL_sv_undef)
            XSRETURN_UNDEF;
        r = curl_multi_cleanup((CURLM *)SvIV(SvRV(http)));
        if(r != CURLM_OK)
            XSRETURN_IV(r);
        SvRV(http) = &PL_sv_undef;
        XSRETURN_IV(0);

void curl_multi_wakeup(SV *http=NULL)
    PPCODE:
        dTHX;
        dSP;
        if(!http || !SvROK(http) || SvRV(http) == &PL_sv_undef)
            XSRETURN_UNDEF;
        int r = curl_multi_wakeup((CURLM *)SvIV(SvRV(http)));
        if(r != CURLM_OK)
            XSRETURN_IV(r);
        XSRETURN_IV(0);

void curl_multi_perform(SV *http=NULL)
    PREINIT:
        int r = 0;
    PPCODE:
        dTHX;
        dSP;
        if(!http || !SvROK(http) || SvRV(http) == &PL_sv_undef)
            XSRETURN_UNDEF;
        r = curl_multi_perform((CURLM *)SvIV(SvRV(http)), &r);
        if(r != CURLM_OK)
            XSRETURN_IV(r);
        XSRETURN_IV(0);

void curl_multi_add_handle(SV *http=NULL, SV *easy=NULL)
    PPCODE:
        dTHX;
        dSP;
        if(!http || !SvROK(http) || SvRV(http) == &PL_sv_undef)
            XSRETURN_UNDEF;
        if(!easy || !SvROK(easy) || SvRV(easy) == &PL_sv_undef)
            XSRETURN_UNDEF;
        int r = curl_multi_add_handle((CURLM *)SvIV(SvRV(http)), (CURL *)SvIV(SvRV(easy)));
        if(r != CURLM_OK)
            XSRETURN_IV(r);
        XSRETURN_IV(0);

void curl_multi_remove_handle(SV *http=NULL, SV *easy=NULL)
    PPCODE:
        dTHX;
        dSP;
        if(!http || !SvROK(http) || SvRV(http) == &PL_sv_undef)
            XSRETURN_UNDEF;
        if(!easy || !SvROK(easy) || SvRV(easy) == &PL_sv_undef)
            XSRETURN_UNDEF;
        int r = curl_multi_remove_handle((CURLM *)SvIV(SvRV(http)), (CURL *)SvIV(SvRV(easy)));
        if(r != CURLM_OK)
            XSRETURN_IV(r);
        XSRETURN_IV(0);

void curl_multi_strerror(int code)
    PPCODE:
        dTHX;
        dSP;
        const char *s = curl_multi_strerror(code);
        if(!s)
            XSRETURN_UNDEF;
        XPUSHs(sv_2mortal(newSVpv(s, 0)));

void curl_multi_timeout(SV *http=NULL)
    PREINIT:
        long l = 0;
    PPCODE:
        dTHX;
        dSP;
        if(!http || !SvROK(http) || SvRV(http) == &PL_sv_undef)
            XSRETURN_UNDEF;
        int r = curl_multi_timeout((CURLM *)SvIV(SvRV(http)), &l);
        if(r != CURLM_OK)
            XSRETURN_UNDEF;
        XSRETURN_IV(l);

void curl_multi_info_read(SV *http=NULL)
    PREINIT:
        int r = 0;
    PPCODE:
        dTHX;
        dSP;
        if(!http || !SvROK(http) || SvRV(http) == &PL_sv_undef)
            XSRETURN_UNDEF;
        CURLMsg *m = curl_multi_info_read((CURLM *)SvIV(SvRV(http)), &r);
        if(!m)
            XSRETURN_UNDEF;
        HV *rh = (HV *)sv_2mortal((SV *)newHV());
        hv_store(rh, "msg"          ,  3, newSViv(m->msg)             , 0);
        hv_store(rh, "result"       ,  6, newSViv(m->data.result)     , 0);
        hv_store(rh, "whatever"     ,  8, newSVpv(m->data.whatever, 0), 0);
        hv_store(rh, "easy_handle"  , 11, newSViv((IV)m->easy_handle) , 0);
        XPUSHs(newRV_inc((SV *)rh));

void curl_multi_setopt(SV *http=NULL, IV c_opt=0, SV *value=NULL)
    PREINIT:
        int r = 0;
        void *_v = NULL;
    PPCODE:
        dTHX;
        dSP;
        if(!http || !SvROK(http) || SvRV(http) == &PL_sv_undef)
            XSRETURN_UNDEF;
        if(!value || !SvOK(value))
            XSRETURN_UNDEF;

        if(c_opt >= CURLOPTTYPE_LONG && c_opt < CURLOPTTYPE_OBJECTPOINT){
            _v = (long *)SvIV(value);
        } else if(c_opt >= CURLOPTTYPE_OBJECTPOINT && c_opt < CURLOPTTYPE_FUNCTIONPOINT){
            if(!SvPOK(value))
                XSRETURN_UNDEF;
            _v = (char *)SvPV_nolen(value);
        } else if(c_opt >= CURLOPTTYPE_FUNCTIONPOINT && c_opt < CURLOPTTYPE_OFF_T){
            XSRETURN_UNDEF;
        } else if(c_opt >= CURLOPTTYPE_OFF_T && c_opt < CURLOPTTYPE_BLOB){
            _v = (curl_off_t *)SvIV(value);
        } else {
            XSRETURN_UNDEF;
        }
        r = curl_multi_setopt((CURLM *)SvIV(SvRV(http)), c_opt, _v);
        if(r != CURLM_OK)
            XSRETURN_IV(r);
        XSRETURN_IV(0);

void curl_multi_fdset(SV *http=NULL)
    PREINIT:
        fd_set r;
        fd_set w;
        fd_set e;
        int max = 0;
        int rt = 0;
    PPCODE:
        dTHX;
        dSP;
        if(!http || !SvROK(http) || SvRV(http) == &PL_sv_undef)
            XSRETURN_UNDEF;
        rt = curl_multi_fdset((CURLM *)SvIV(SvRV(http)), &r, &w, &e, &max);
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

void curl_multi_poll(SV *http=NULL, SV *extrafds=&PL_sv_undef, SV *timeout=&PL_sv_undef, SV *numfds=&PL_sv_undef)
    PREINIT:
        int r = 0;
        int nfds = 0;
    PPCODE:
        dTHX;
        dSP;
        if(!http || !SvROK(http) || SvRV(http) == &PL_sv_undef)
            XSRETURN_UNDEF;
        r = curl_multi_poll((CURLM *)SvIV(SvRV(http)), NULL, 0, SvIV(timeout), &nfds);
        if(r != CURLM_OK)
            XSRETURN_IV(r);
        SvIV_set(numfds, nfds);
        XSRETURN_IV(0);

void curl_multi_wait(SV *http=NULL, SV *extrafds=&PL_sv_undef, SV *timeout=&PL_sv_undef, SV *numfds=&PL_sv_undef)
    PREINIT:
        int r = 0;
        int nfds = 0;
    PPCODE:
        dTHX;
        dSP;
        if(!http || !SvROK(http) || SvRV(http) == &PL_sv_undef)
            XSRETURN_UNDEF;
        r = curl_multi_wait((CURLM *)SvIV(SvRV(http)), NULL, 0, SvIV(timeout), &nfds);
        if(r != CURLM_OK)
            XSRETURN_IV(r);
        SvIV_set(numfds, nfds);
        XSRETURN_IV(0);

void curl_multi_get_handles(SV *http=NULL)
    PPCODE:
        dTHX;
#if (LIBCURL_VERSION_NUM >= 0x080400)
        dSP;
        if(!http || !SvROK(http) || SvRV(http) == &PL_sv_undef)
            XSRETURN_UNDEF;
        CURLMcode r;
        int n;
        CURL **e = curl_multi_get_handles((CURLM *)SvIV(SvRV(http)), &n);
        if(!e)
            XSRETURN_UNDEF;
        AV *av = newAV();
        for(int i=0; i<n; i++){
            SV *sv = sv_newmortal();
            sv_setref_pv(sv, "http::curl::easy", (void *)e[i]);
            SvREADONLY_on(sv);
            av_push(av, sv);
        }
        curl_free(e);
        XPUSHs(sv_2mortal(newRV_noinc((SV *)av));
#else
        XSRETURN_EMPTY;
#endif

