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
        newCONSTSUB(stash, "CURLE_OK"           , newSViv(CURLE_OK));
        newCONSTSUB(stash, "CURLE_BAD_FUNCTION_ARGUMENT", newSViv(CURLE_BAD_FUNCTION_ARGUMENT));
        newCONSTSUB(stash, "CURLE_UNSUPPORTED_PROTOCOL", newSViv(CURLE_UNSUPPORTED_PROTOCOL));
        newCONSTSUB(stash, "CURLE_UNKNOWN_OPTION", newSViv(CURLE_UNKNOWN_OPTION));
        newCONSTSUB(stash, "CURLE_NOT_BUILT_IN", newSViv(CURLE_NOT_BUILT_IN));
        newCONSTSUB(stash, "CURLE_FAILED_INIT"  , newSViv(CURLE_FAILED_INIT));
        newCONSTSUB(stash, "CURLE_URL_MALFORMAT", newSViv(CURLE_URL_MALFORMAT));
        newCONSTSUB(stash, "CURLE_COULDNT_RESOLVE_PROXY", newSViv(CURLE_COULDNT_RESOLVE_PROXY));
        newCONSTSUB(stash, "CURLOPT_URL"        , newSViv(CURLOPT_URL));
        newCONSTSUB(stash, "CURLOPT_SHARE"      , newSViv(CURLOPT_SHARE));
        newCONSTSUB(stash, "CURLOPT_ERRORBUFFER", newSViv(CURLOPT_ERRORBUFFER));
        newCONSTSUB(stash, "CURLOPT_VERBOSE"    , newSViv(CURLOPT_VERBOSE));
        newCONSTSUB(stash, "CURLOPT_STDERR"     , newSViv(CURLOPT_STDERR));
        newCONSTSUB(stash, "CURLOPT_WRITEFUNCTION", newSViv(CURLOPT_WRITEFUNCTION));
        newCONSTSUB(stash, "CURLOPT_WRITEDATA"  , newSViv(CURLOPT_WRITEDATA));
        newCONSTSUB(stash, "CURLOPT_READFUNCTION", newSViv(CURLOPT_READFUNCTION));
        newCONSTSUB(stash, "CURLOPT_READDATA"    , newSViv(CURLOPT_READDATA));
        newCONSTSUB(stash, "CURLOPT_HEADERFUNCTION", newSViv(CURLOPT_HEADERFUNCTION));
        newCONSTSUB(stash, "CURLOPT_HEADERDATA"  , newSViv(CURLOPT_HEADERDATA));
        newCONSTSUB(stash, "CURLOPT_HTTPHEADER"  , newSViv(CURLOPT_HTTPHEADER));
        newCONSTSUB(stash, "CURLOPT_POST"        , newSViv(CURLOPT_POST));
        newCONSTSUB(stash, "CURLOPT_POSTFIELDS"   , newSViv(CURLOPT_POSTFIELDS));
        newCONSTSUB(stash, "CURLOPT_POSTFIELDSIZE", newSViv(CURLOPT_POSTFIELDSIZE));
        newCONSTSUB(stash, "CURLOPT_POSTFIELDSIZE_LARGE", newSViv(CURLOPT_POSTFIELDSIZE_LARGE));
        newCONSTSUB(stash, "CURLOPT_FOLLOWLOCATION", newSViv(CURLOPT_FOLLOWLOCATION));
        newCONSTSUB(stash, "CURLINFO_RESPONSE_CODE", newSViv(CURLINFO_RESPONSE_CODE));
        newCONSTSUB(stash, "CURLINFO_EFFECTIVE_URL", newSViv(CURLINFO_EFFECTIVE_URL));
        newCONSTSUB(stash, "CURLINFO_EFFECTIVE_METHOD", newSViv(CURLINFO_EFFECTIVE_METHOD));
        newCONSTSUB(stash, "CURLINFO_REDIRECT_URL", newSViv(CURLINFO_REDIRECT_URL));
        newCONSTSUB(stash, "CURLINFO_CONTENT_TYPE", newSViv(CURLINFO_CONTENT_TYPE));
        newCONSTSUB(stash, "CURLINFO_PRIVATE", newSViv(CURLINFO_PRIVATE));
        newCONSTSUB(stash, "CURLINFO_PRIMARY_IP", newSViv(CURLINFO_PRIMARY_IP));
        newCONSTSUB(stash, "CURLINFO_PRIMARY_PORT", newSViv(CURLINFO_PRIMARY_PORT));
        newCONSTSUB(stash, "CURLINFO_LOCAL_IP", newSViv(CURLINFO_LOCAL_IP));
        newCONSTSUB(stash, "CURLINFO_LOCAL_PORT", newSViv(CURLINFO_LOCAL_PORT));
        newCONSTSUB(stash, "CURLINFO_OS_ERRNO", newSViv(CURLINFO_OS_ERRNO));
        newCONSTSUB(stash, "CURLINFO_NUM_CONNECTS", newSViv(CURLINFO_NUM_CONNECTS));
        newCONSTSUB(stash, "CURLINFO_PROXYAUTH_AVAIL", newSViv(CURLINFO_PROXYAUTH_AVAIL));
        newCONSTSUB(stash, "CURLINFO_LASTSOCKET", newSViv(CURLINFO_LASTSOCKET));
        newCONSTSUB(stash, "CURLINFO_FILETIME", newSViv(CURLINFO_FILETIME));
        newCONSTSUB(stash, "CURLINFO_REDIRECT_COUNT", newSViv(CURLINFO_REDIRECT_COUNT));
        newCONSTSUB(stash, "CURLINFO_HTTP_CONNECTCODE", newSViv(CURLINFO_HTTP_CONNECTCODE));
        newCONSTSUB(stash, "CURLINFO_HTTPAUTH_AVAIL", newSViv(CURLINFO_HTTPAUTH_AVAIL));
        newCONSTSUB(stash, "CURLINFO_HTTP_VERSION", newSViv(CURLINFO_HTTP_VERSION));
        newCONSTSUB(stash, "CURLINFO_PROTOCOL", newSViv(CURLINFO_PROTOCOL));
        newCONSTSUB(stash, "CURLINFO_SCHEME", newSViv(CURLINFO_SCHEME));
        newCONSTSUB(stash, "CURLINFO_CERTINFO", newSViv(CURLINFO_CERTINFO));
        newCONSTSUB(stash, "CURLINFO_CONDITION_UNMET", newSViv(CURLINFO_CONDITION_UNMET));
        newCONSTSUB(stash, "CURLINFO_RTSP_CLIENT_CSEQ", newSViv(CURLINFO_RTSP_CLIENT_CSEQ));
        newCONSTSUB(stash, "CURLINFO_RTSP_CSEQ_RECV", newSViv(CURLINFO_RTSP_CSEQ_RECV));
        newCONSTSUB(stash, "CURLINFO_RTSP_SERVER_CSEQ", newSViv(CURLINFO_RTSP_SERVER_CSEQ));
        newCONSTSUB(stash, "CURLINFO_TOTAL_TIME", newSViv(CURLINFO_TOTAL_TIME));
        newCONSTSUB(stash, "CURLINFO_NAMELOOKUP_TIME", newSViv(CURLINFO_NAMELOOKUP_TIME));
        newCONSTSUB(stash, "CURLINFO_CONNECT_TIME", newSViv(CURLINFO_CONNECT_TIME));
        newCONSTSUB(stash, "CURLINFO_APPCONNECT_TIME", newSViv(CURLINFO_APPCONNECT_TIME));
        newCONSTSUB(stash, "CURLINFO_PRETRANSFER_TIME", newSViv(CURLINFO_PRETRANSFER_TIME));
        newCONSTSUB(stash, "CURLINFO_STARTTRANSFER_TIME", newSViv(CURLINFO_STARTTRANSFER_TIME));
        newCONSTSUB(stash, "CURLINFO_REDIRECT_TIME", newSViv(CURLINFO_REDIRECT_TIME));
        newCONSTSUB(stash, "CURLINFO_SIZE_UPLOAD", newSViv(CURLINFO_SIZE_UPLOAD));
        newCONSTSUB(stash, "CURLINFO_SIZE_DOWNLOAD", newSViv(CURLINFO_SIZE_DOWNLOAD));
        newCONSTSUB(stash, "CURLINFO_SPEED_DOWNLOAD", newSViv(CURLINFO_SPEED_DOWNLOAD));
        newCONSTSUB(stash, "CURLINFO_SPEED_UPLOAD", newSViv(CURLINFO_SPEED_UPLOAD));
        newCONSTSUB(stash, "CURLINFO_HEADER_SIZE", newSViv(CURLINFO_HEADER_SIZE));
        newCONSTSUB(stash, "CURLINFO_REQUEST_SIZE", newSViv(CURLINFO_REQUEST_SIZE));
        newCONSTSUB(stash, "CURLINFO_SSL_VERIFYRESULT", newSViv(CURLINFO_SSL_VERIFYRESULT));
        newCONSTSUB(stash, "CURLINFO_CONTENT_LENGTH_DOWNLOAD", newSViv(CURLINFO_CONTENT_LENGTH_DOWNLOAD));
        newCONSTSUB(stash, "CURLINFO_CONTENT_LENGTH_UPLOAD", newSViv(CURLINFO_CONTENT_LENGTH_UPLOAD));
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
        config = ST(0);
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
        ST(0) = &PL_sv_undef;
        SV *sv = sv_newmortal();
        sv_setref_pv(sv, "http::curl::easy", (void *)c);
        SvREADONLY_on(sv);
        ST(0) = sv;
        XSRETURN(1);

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
        ST(0) = sv_2mortal(newSVpv(s, 0));
        XSRETURN(1);

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
        if(c_opt == CURLOPT_URL){
            if(!SvPOK(value))
                XSRETURN_NO;
            _v = SvPV_nolen(value);
        } else if(c_opt == CURLOPT_ERRORBUFFER){
            XSRETURN_NO;
        } else if(c_opt == CURLOPT_VERBOSE){
            _v = (void *)SvIV(value);
            //printf("p: %p, _v: %d\n", SvIV(SvRV(http)), _v);
        } else {
            XSRETURN_NO;
        }
        r = curl_easy_setopt((CURL *)SvIV(SvRV(http)), c_opt, _v);
        if(r != CURLE_OK)
            XSRETURN_IV(r);
        XSRETURN_IV(0);

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
        ST(0) = sv;
        XSRETURN(1);

void curl_easy_escape(...)
    SV *url=NULL;
    PREINIT:
        char *s = NULL;
    PPCODE:
        dTHX;
        dSP;
        if(items < 1)
            XSRETURN_UNDEF;
        url = ST(0);
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
        ST(0) = sv_2mortal(newSVpv(s, 0));
        curl_free(s);
        XSRETURN(1);

void curl_easy_unescape(...)
    SV *url=NULL;
    PREINIT:
        char *s = NULL;
    PPCODE:
        dTHX;
        dSP;
        if(items < 1)
            XSRETURN_UNDEF;
        url = ST(0);
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
        ST(0) = sv_2mortal(newSVpv(s, 0));
        curl_free(s);
        XSRETURN(1);

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
