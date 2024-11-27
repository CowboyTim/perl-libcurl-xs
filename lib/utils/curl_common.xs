#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <curl/curl.h>

MODULE = utils::curl_common                PACKAGE = http

void curl_global_init(int flags=CURL_GLOBAL_DEFAULT)
    PREINIT:
        int r;
    CODE:
        dTHX;
        dSP;
        r = curl_global_init(flags);
        if(r != 0)
            XSRETURN_NO;
        XSRETURN_YES;

void curl_global_cleanup()
    CODE:
        dTHX;
        dSP;
        curl_global_cleanup();
        XSRETURN_YES;

void curl_global_trace(...)
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
            XSRETURN_UNDEF;
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

void curl_getdate(...)
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

void curl_version_info(...)
    PREINIT:
        struct curl_version_info_data *vi = NULL;
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

void curl_version(...)
    PPCODE:
        dTHX;
        dSP;
        XPUSHs(sv_2mortal(newSVpv(curl_version(), 0)));
