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
        newCONSTSUB(stash, "CURLE_OK"                   , newSViv(CURLE_OK));
        newCONSTSUB(stash, "CURLE_BAD_FUNCTION_ARGUMENT", newSViv(CURLE_BAD_FUNCTION_ARGUMENT));
        newCONSTSUB(stash, "CURLE_UNSUPPORTED_PROTOCOL" , newSViv(CURLE_UNSUPPORTED_PROTOCOL));
        newCONSTSUB(stash, "CURLE_UNKNOWN_OPTION"       , newSViv(CURLE_UNKNOWN_OPTION));
        newCONSTSUB(stash, "CURLE_NOT_BUILT_IN"         , newSViv(CURLE_NOT_BUILT_IN));
        newCONSTSUB(stash, "CURLE_FAILED_INIT"          , newSViv(CURLE_FAILED_INIT));
        newCONSTSUB(stash, "CURLE_URL_MALFORMAT"        , newSViv(CURLE_URL_MALFORMAT));
        newCONSTSUB(stash, "CURLE_COULDNT_RESOLVE_PROXY", newSViv(CURLE_COULDNT_RESOLVE_PROXY));
}

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
        SV *config = NULL;
        int r = 0;
    PPCODE:
        dTHX;
        dSP;
#if (LIBCURL_VERSION_NUM >= 0x080000)
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

        //printf("p: %p, f: %d & %d\n", SvIV(SvRV(http)), c_opt, CURLOPT_VERBOSE);
        if(
               c_opt == CURLOPT_URL
        ){
            if(!SvPOK(value))
                XSRETURN_UNDEF;
            _v = SvPV_nolen(value);
        } else if(
               c_opt == CURLOPT_ERRORBUFFER
        ){
            XSRETURN_UNDEF;
        } else if(
               c_opt == CURLOPT_VERBOSE
            || c_opt == CURLOPT_TCP_KEEPALIVE
            || c_opt == CURLOPT_TCP_KEEPIDLE
            || c_opt == CURLOPT_TCP_KEEPINTVL
        ){
            _v = (void *)SvIV(value);
            //printf("p: %p, _v: %d\n", SvIV(SvRV(http)), _v);
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

void curl_easy_getinfo(SV *http=NULL, int info=0)
    PREINIT:
        long l = 0;
        int r = 0;
        double d = 0;
        char *s = NULL;
    PPCODE:
        dTHX;
        dSP;
        if(!http || !SvROK(http) || SvRV(http) == &PL_sv_undef)
            XSRETURN_UNDEF;
        if(info == 0)
            XSRETURN_UNDEF;
        if(
               info == CURLINFO_EFFECTIVE_URL
            || info == CURLINFO_CONTENT_TYPE
            || info == CURLINFO_PRIVATE
            || info == CURLINFO_FTP_ENTRY_PATH
            || info == CURLINFO_REDIRECT_URL
            || info == CURLINFO_PRIMARY_IP
            || info == CURLINFO_RTSP_SESSION_ID
            || info == CURLINFO_LOCAL_IP
            || info == CURLINFO_SCHEME
            || info == CURLINFO_EFFECTIVE_METHOD
            || info == CURLINFO_REFERER
        ){
            r = curl_easy_getinfo((CURL *)SvIV(SvRV(http)), info, &s);
            if(r != CURLE_OK)
                XSRETURN_UNDEF;
            ST(0) = sv_2mortal(newSVpv(s, 0));
            XSRETURN(1);
        } else if(
               info == CURLINFO_RESPONSE_CODE
            || info == CURLINFO_HEADER_SIZE
            || info == CURLINFO_REQUEST_SIZE
            || info == CURLINFO_SSL_VERIFYRESULT
            || info == CURLINFO_FILETIME
            || info == CURLINFO_REDIRECT_COUNT
            || info == CURLINFO_HTTP_CONNECTCODE
            || info == CURLINFO_HTTPAUTH_AVAIL
            || info == CURLINFO_PROXYAUTH_AVAIL
            || info == CURLINFO_OS_ERRNO
            || info == CURLINFO_NUM_CONNECTS
            || info == CURLINFO_LASTSOCKET
            || info == CURLINFO_CONDITION_UNMET
            || info == CURLINFO_RTSP_CLIENT_CSEQ
            || info == CURLINFO_RTSP_SERVER_CSEQ
            || info == CURLINFO_RTSP_CSEQ_RECV
            || info == CURLINFO_PRIMARY_PORT
            || info == CURLINFO_LOCAL_PORT
            || info == CURLINFO_HTTP_VERSION
            || info == CURLINFO_PROXY_SSL_VERIFYRESULT
            || info == CURLINFO_PROTOCOL
            || info == CURLINFO_PROXY_ERROR
        ){
            r = curl_easy_getinfo((CURL *)SvIV(SvRV(http)), info, &l);
            if(r != CURLE_OK)
                XSRETURN_UNDEF;
            XSRETURN_IV(l);
        } else if(
               info == CURLINFO_TOTAL_TIME
            || info == CURLINFO_NAMELOOKUP_TIME
            || info == CURLINFO_CONNECT_TIME
            || info == CURLINFO_PRETRANSFER_TIME
            || info == CURLINFO_SIZE_UPLOAD
            || info == CURLINFO_SIZE_DOWNLOAD
            || info == CURLINFO_SPEED_DOWNLOAD
            || info == CURLINFO_SPEED_UPLOAD
            || info == CURLINFO_CONTENT_LENGTH_DOWNLOAD
            || info == CURLINFO_CONTENT_LENGTH_UPLOAD
            || info == CURLINFO_STARTTRANSFER_TIME
            || info == CURLINFO_REDIRECT_TIME
            || info == CURLINFO_APPCONNECT_TIME
        ){
            r = curl_easy_getinfo((CURL *)SvIV(SvRV(http)), info, &d);
            if(r != CURLE_OK)
                XSRETURN_UNDEF;
            XSRETURN_NV(d);
        } else if(
               info == CURLINFO_SIZE_UPLOAD_T
            || info == CURLINFO_SIZE_DOWNLOAD_T
            || info == CURLINFO_SPEED_DOWNLOAD_T
            || info == CURLINFO_SPEED_UPLOAD_T
            || info == CURLINFO_FILETIME_T
            || info == CURLINFO_CONTENT_LENGTH_DOWNLOAD_T
            || info == CURLINFO_CONTENT_LENGTH_UPLOAD_T
            || info == CURLINFO_TOTAL_TIME_T
            || info == CURLINFO_NAMELOOKUP_TIME_T
            || info == CURLINFO_CONNECT_TIME_T
            || info == CURLINFO_PRETRANSFER_TIME_T
            || info == CURLINFO_STARTTRANSFER_TIME_T
            || info == CURLINFO_REDIRECT_TIME_T
            || info == CURLINFO_APPCONNECT_TIME_T
            || info == CURLINFO_RETRY_AFTER
        ){
            r = curl_easy_getinfo((CURL *)SvIV(SvRV(http)), info, &d);
            if(r != CURLE_OK)
                XSRETURN_UNDEF;
            XSRETURN_NV(d/1000);
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
