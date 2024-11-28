#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <curl/curl.h>

MODULE = utils::curl_common                PACKAGE = http

VERSIONCHECK: DISABLE
PROTOTYPES: DISABLE

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

void curl_version(...)
    PPCODE:
        dTHX;
        dSP;
        XPUSHs(sv_2mortal(newSVpv(curl_version(), 0)));
