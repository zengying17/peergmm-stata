*! version 0.6.1  09aug2026
*! peer_cra: Peer-effect GMM under conditional random assignment
*!
*! Current contract:
*!  - Public command peer_cra mirrors the PeerCRA R estimator.
*!  - A concentrated golden-section solution initializes each fixed-weight
*!    stage; covariate models then run the joint bounded BFGS refinement.
*!    No-covariate models use the exact scalar solution.
*!  - Stage two uses the bias-corrected residual weight when positive
*!    definite and otherwise retains the first-step weight.
*!  - Final covariance status is tracked internally. The public
*!    e(inference_available) flag records whether covariance inference exists.
*!  - Final and stage-one lower-block eigenvalue-repair diagnostics remain
*!    internal and produce a notice only when a repair activates.
*!  - Exact duplicate or absorbed covariates are dropped in supplied-variable
*!    order; e(collinear_dropped) records the count.
*!  - Optimizer-status differences across R and Mata remain visible and do
*!    not override finite numerical agreement under the maintained tolerance.
*!
*! Packaging:
*!  - The canonical Mata source is stata-command/src/peergmm.mata.
*!  - lpeergmm.mlib is the compiled fast path. lpeergmm.mata is shipped
*!    beside it as a source fallback for older Stata releases.
*!  - The maintained 10-configuration x 3-seed R--Stata grid is the release
*!    comparison gate. Full release history is in changelog.md.

program define peer_cra, eclass
    version 14.0

    if c(stata_version) < 16 {
        di as error "peer_cra requires Stata 16 or newer."
        exit 9
    }

    syntax varlist(min=1 max=1 numeric) [if] [in], URN(varname numeric) Group(varname numeric) [OWN(varlist numeric) PEER(varlist numeric) Lambda_bounds(numlist min=2 max=2) RANKtol(real 0.0000001) OPTim_ptol(real 0.00000000000001) OPTim_vtol(real 0.0000000000001) MAXiter(integer 2000)]

    local depvar `varlist'

    if ("`lambda_bounds'" == "") local lambda_bounds "-0.99 0.99"
    tokenize `lambda_bounds'
    local lb_lo = `1'
    local lb_hi = `2'

    if `lb_lo' >= `lb_hi' {
        di as error "lambda_bounds: first value must be strictly less than second."
        exit 198
    }
    if `lb_lo' <= -1 | `lb_hi' >= 1 {
        di as error "lambda_bounds must satisfy -1 < lo < hi < 1."
        exit 198
    }
    if `ranktol' <= 0 | `ranktol' >= 1 {
        di as error "ranktol() must be strictly between 0 and 1."
        exit 198
    }
    marksample touse
    markout `touse' `depvar' `urn' `group' `own' `peer'

    qui count if `touse'
    if r(N) == 0 {
        di as error "No observations."
        exit 2000
    }

    tempvar sortidx esample
    gen long `sortidx' = _n
    gen byte `esample' = 0
    sort `touse' `urn' `group' `sortidx'

    * Mata computes point estimates, variance, diagnostics, urn FE.
    * Writes b (1xk), V (kxk), scalars, coefficient label stripe,
    * alpha (Rx1), and urn_info (Rx3) to the tempname matrices provided.
    tempname b V scalars coef_stripe alpha urn_info
    capture quietly mata: mata mlib index
    capture mata: pg_fit("`depvar'", "`urn'", "`group'", ///
        "`own'", "`peer'", `lb_lo', `lb_hi', ///
        `ranktol', ///
        `optim_ptol', `optim_vtol', `maxiter', "`touse'", "`esample'", ///
        "`b'", "`V'", "`scalars'", "`coef_stripe'", ///
        "`alpha'", "`urn_info'")
    if _rc {
        local pg_fit_rc = _rc
        if `pg_fit_rc' != 3499 {
            sort `sortidx'
            exit `pg_fit_rc'
        }
        capture findfile lpeergmm.mata
        if _rc {
            di as error "peer_cra: Mata function pg_fit() is unavailable."
            di as error "The compiled lpeergmm.mlib may be missing or too new for this Stata."
            di as error "Install lpeergmm.mata beside peer_cra.ado or rebuild lpeergmm.mlib with this Stata."
            exit `pg_fit_rc'
        }
        local pg_source "`r(fn)'"
        di as text "peer_cra: compiling Mata source fallback for this Stata."
        capture quietly do "`pg_source'"
        if _rc {
            local pg_source_rc = _rc
            di as error "peer_cra: failed to compile Mata source fallback lpeergmm.mata."
            noisily do "`pg_source'"
            exit `pg_source_rc'
        }
        mata: pg_fit("`depvar'", "`urn'", "`group'", ///
            "`own'", "`peer'", `lb_lo', `lb_hi', ///
            `ranktol', ///
            `optim_ptol', `optim_vtol', `maxiter', "`touse'", "`esample'", ///
            "`b'", "`V'", "`scalars'", "`coef_stripe'", ///
            "`alpha'", "`urn_info'")
    }

    * Restore original row order.
    sort `sortidx'

    local N            = `scalars'[1, 1]
    local N_urns       = `scalars'[2, 1]
    local N_groups     = `scalars'[3, 1]
    local converged    = `scalars'[4, 1]
    local crit1        = `scalars'[5, 1]
    local crit2        = `scalars'[6, 1]
    local N_pre        = `scalars'[7, 1]
    local N_urns_pre   = `scalars'[8, 1]
    local N_groups_pre = `scalars'[9, 1]
    local status_code  = `scalars'[10, 1]
    local collinear_dropped = `scalars'[11, 1]
    local stage2_weight_used_first = `scalars'[12, 1]
    local final_vcov_used_first = `scalars'[13, 1]
    local final_vcov_nonpd = `scalars'[14, 1]
    local inference_available = `scalars'[15, 1]
    local vcov_status_code = `scalars'[16, 1]
    local scalar_rows = rowsof(`scalars')
    if `scalar_rows' >= 24 {
        local vhat_lower_projected = `scalars'[17, 1]
        local vhat_lower_min_eig_raw = `scalars'[18, 1]
        local vhat_lower_n_eig_repaired = `scalars'[19, 1]
        local vhat_lower_eig_floor = `scalars'[20, 1]
        local vhat_s1_lower_projected = `scalars'[21, 1]
        local vhat_s1_lower_min_eig_raw = `scalars'[22, 1]
        local vhat_s1_lower_n_eig_repaired = `scalars'[23, 1]
        local vhat_s1_lower_eig_floor = `scalars'[24, 1]
    }
    else {
        local vhat_lower_projected = 0
        local vhat_lower_min_eig_raw = .
        local vhat_lower_n_eig_repaired = 0
        local vhat_lower_eig_floor = .
        local vhat_s1_lower_projected = 0
        local vhat_s1_lower_min_eig_raw = .
        local vhat_s1_lower_n_eig_repaired = 0
        local vhat_s1_lower_eig_floor = .
    }

    * Translate the Mata-side status enum (see pg_run_optimize) to a
    * human-readable string. Mirror of the R side's optimizer_status.
    if      `status_code' == 0 local optimizer_status "failed"
    else if `status_code' == 1 local optimizer_status "converged"
    * Code 2 is retained only to decode an older library already loaded in
    * memory; the current Mata source and rebuilt library never return it.
    else if `status_code' == 2 local optimizer_status "short_circuit_exact_id"
    else if `status_code' == 3 local optimizer_status "short_circuit_no_covariates"
    else                       local optimizer_status "unknown"

    if      `vcov_status_code' == 0 local vcov_status "final_option_b"
    else if `vcov_status_code' == 1 local vcov_status "stage2_weight_fallback_final_option_b"
    else if `vcov_status_code' == 2 local vcov_status "stage1_residual_final_fallback"
    else if `vcov_status_code' == 3 local vcov_status "unavailable_both_fallback"
    else {
        di as error "peer_cra: unknown Mata covariance-status code `vcov_status_code'."
        exit 498
    }

    if `inference_available' {
        ereturn post `b' `V', esample(`esample') depname(`depvar') obs(`N')
    }
    else {
        ereturn post `b', esample(`esample') depname(`depvar') obs(`N')
    }
    ereturn scalar N_urns       = `N_urns'
    ereturn scalar N_groups     = `N_groups'
    ereturn scalar converged    = `converged'
    ereturn local  optimizer_status "`optimizer_status'"
    ereturn scalar criterion_s1 = `crit1'
    ereturn scalar criterion_s2 = `crit2'
    ereturn scalar lambda_lb    = `lb_lo'
    ereturn scalar lambda_ub    = `lb_hi'
    ereturn scalar rank_tol     = `ranktol'
    ereturn scalar collinear_dropped = `collinear_dropped'
    ereturn scalar inference_available = `inference_available'
    ereturn local  cmd          "peer_cra"
    ereturn local  depvar       "`depvar'"
    ereturn local  urn          "`urn'"
    ereturn local  group        "`group'"
    ereturn local  own          "`own'"
    ereturn local  peer         "`peer'"
    ereturn local  title        "Peer-effect GMM under conditional random assignment"
    ereturn local  predict      "peer_cra_p"
    ereturn matrix alpha     = `alpha'
    ereturn matrix urn_info  = `urn_info'

    * Display
    di _n as text "PeerCRA"
    di as text "Observations: " as result e(N) ///
       as text "   Urns: " as result e(N_urns) ///
       as text "   Peer groups: " as result e(N_groups)
    if `N_pre' != `N' | `N_urns_pre' != `N_urns' | `N_groups_pre' != `N_groups' {
        di as text "Dropped during cleaning: " ///
           as result `N_pre' - `N'               as text " obs, " ///
           as result `N_groups_pre' - `N_groups' as text " groups, " ///
           as result `N_urns_pre' - `N_urns'     as text " urns"
    }
    if `collinear_dropped' > 0 {
        di as text "Dropped collinear/absorbed covariates: " ///
           as result `collinear_dropped'
    }
    if !`converged' {
        di as error "Warning: optimization did not converge; estimates may be unreliable."
    }
    if `stage2_weight_used_first' {
        di as text "Note: stage two retained the first-step weighting matrix."
    }
    if "`vcov_status'" == "stage1_residual_final_fallback" {
        di as text "Note: inference uses the stage-one residual covariance."
    }
    if !`inference_available' {
        di as error "Warning: inference is unavailable; point estimates are shown without standard errors."
    }
    if `vhat_lower_projected' | `vhat_s1_lower_projected' {
        di as text "Note: numerical covariance repair was applied."
    }
    di
    ereturn display

    * Boundary warning (mirror R's peer_cra boundary-warning block).
    tempname lambda_hat
    scalar `lambda_hat' = e(b)[1, 1]
    if abs(`lambda_hat' - e(lambda_lb)) < 1e-3 | abs(`lambda_hat' - e(lambda_ub)) < 1e-3 {
        di as error "warning: lambda_hat = " as result %9.4f `lambda_hat' ///
           as error " is at the boundary of lambda_bounds = (" ///
           as result e(lambda_lb) as error ", " as result e(lambda_ub) ///
           as error "); typically indicates weak identification."
    }

end
