*! version 0.6.0  09aug2026
*! peer_cra_p: predict after peer_cra
*! Supports: xb (default), residuals, fitted, alpha.
*!   xb        lambda * W Y + Z beta   (structural fit, no urn FE)
*!   alpha     alpha_hat_{r(i)}        (urn fixed effect at each obs)
*!   fitted    xb + alpha              (full structural prediction)
*!   residuals Y - fitted              (structural residuals)
*! If the shipped lpeergmm.mlib was compiled by a newer Stata, this
*! predict companion compiles lpeergmm.mata in-session before calling
*! pg_predict().

program define peer_cra_p
    version 14.0

    if c(stata_version) < 16 {
        di as error "peer_cra_p requires Stata 16 or newer."
        exit 9
    }

    syntax newvarname [if] [in] [, ///
        XB Residuals Fitted Alpha]

    if ("`e(cmd)'" != "peer_cra") {
        di as error "peer_cra_p: last estimation command was not peer_cra"
        exit 301
    }

    local n_opts : word count `xb' `residuals' `fitted' `alpha'
    if `n_opts' > 1 {
        di as error "only one of xb, residuals, fitted, alpha may be specified"
        exit 198
    }
    if ("`residuals'" != "") local mode "residuals"
    else if ("`fitted'" != "")   local mode "fitted"
    else if ("`alpha'" != "")    local mode "alpha"
    else                          local mode "xb"

    marksample requested, novarlist

    tempvar sortidx esample
    qui gen long `sortidx' = _n
    qui gen byte `esample' = e(sample)
    sort `esample' `e(urn)' `e(group)' `sortidx'

    qui gen double `varlist' = .

    tempname b_mat alpha_mat
    matrix `b_mat'     = e(b)
    matrix `alpha_mat' = e(alpha)

    capture quietly mata: mata mlib index
    capture mata: pg_predict("`e(depvar)'", "`e(urn)'", "`e(group)'", ///
                              "`e(own)'", "`e(peer)'", "`esample'", ///
                              "`varlist'", "`mode'", "`b_mat'", "`alpha_mat'")
    if _rc {
        local pg_predict_rc = _rc
        if `pg_predict_rc' != 3499 {
            sort `sortidx'
            exit `pg_predict_rc'
        }
        capture findfile lpeergmm.mata
        if _rc {
            di as error "peer_cra_p: Mata function pg_predict() is unavailable."
            di as error "The compiled lpeergmm.mlib may be missing or too new for this Stata."
            di as error "Install lpeergmm.mata beside peer_cra_p.ado or rebuild lpeergmm.mlib with this Stata."
            exit `pg_predict_rc'
        }
        local pg_source "`r(fn)'"
        di as text "peer_cra_p: compiling Mata source fallback for this Stata."
        capture quietly do "`pg_source'"
        if _rc {
            local pg_source_rc = _rc
            di as error "peer_cra_p: failed to compile Mata source fallback lpeergmm.mata."
            noisily do "`pg_source'"
            exit `pg_source_rc'
        }
        mata: pg_predict("`e(depvar)'", "`e(urn)'", "`e(group)'", ///
                          "`e(own)'", "`e(peer)'", "`esample'", ///
                          "`varlist'", "`mode'", "`b_mat'", "`alpha_mat'")
    }

    qui replace `varlist' = . if !`requested' | !e(sample)
    sort `sortidx'
end
