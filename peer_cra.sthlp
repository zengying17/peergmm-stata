{smcl}
{* *! version 0.6.1  09aug2026}{...}
{title:Title}

{p2colset 5 17 19 2}{...}
{p2col:{bf:peer_cra} {hline 2}}Estimation and Inference for Peer Effects under Conditional Random Assignment{p_end}
{p2colreset}{...}

{title:Description}

{pstd}
{cmd:peer_cra} estimates endogenous peer effects when individuals are assigned
to peer groups within assignment urns. It implements the two-step GMM estimator
developed in {it:Estimation and Inference for Peer Effects under Conditional
Random Assignment}. The command requires Stata 16 or newer.

{title:Basic syntax}

{p 8 16 2}
{cmd:peer_cra} {it:depvar} {ifin}{cmd:,}
{opt urn(varname)} {opt g:roup(varname)}
[{opt own(varlist)} {opt peer(varlist)}]

{pstd}
Each retained observation must identify one assignment urn and one peer group
nested within that urn. Every retained peer group must contain at least two
observations, and every retained urn must contain at least two peer groups.
Missing observations and structurally invalid groups are removed before
estimation.

{title:Minimal example}

{phang}{cmd:. peer_cra Y, urn(urn_id) group(group_id) own(x1) peer(x2)}{p_end}

{title:Coefficient interpretation}

{pstd}
The coefficient named {cmd:lambda} is the endogenous peer-effect coefficient.
Variables in {opt own()} enter as individual covariates and keep their variable
names. Variables in {opt peer()} enter through peer averages and are labeled
with the prefix {cmd:ave_}. The coefficient table reports estimates, standard
errors, z statistics, p-values, and confidence intervals when inference is
available.

{title:Postestimation: {cmd:predict}}

{phang}{cmd:predict} {it:newvar} [{cmd:if}] [{cmd:in}] [{cmd:,} {it:statistic}]{p_end}

{pstd}where {it:statistic} is one of:

{synoptset 18 tabbed}{...}
{synopt:{opt xb}}structural prediction {it:lambda W Y + Z beta} without urn fixed effects; the default{p_end}
{synopt:{opt alpha}}estimated urn fixed effect at each observation{p_end}
{synopt:{opt fitted}}full fitted value {it:xb + alpha}{p_end}
{synopt:{opt residuals}}structural residual {it:Y - fitted}{p_end}
{synoptline}

{phang}{cmd:. predict fitted_y, fitted}{p_end}
{phang}{cmd:. predict resid, residuals}{p_end}

{pstd}
{cmd:e(sample)} is the exact post-cleaning estimation sample. Predictions
reconstruct peer quantities using that full sample, even when {cmd:if} or
{cmd:in} limits where results are stored. Modifying the outcome, urn, group, or
covariate variables after estimation changes the reconstructed predictions.

{title:Options}

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt urn(varname)}}numeric variable identifying assignment urns; required{p_end}
{synopt:{opt group(varname)}}numeric variable identifying peer groups nested within urns; required{p_end}
{synopt:{opt own(varlist)}}own-effect covariates entering the structural equation directly{p_end}
{synopt:{opt peer(varlist)}}peer-effect covariates entering through peer-group averages{p_end}
{synoptline}

{title:Advanced numerical options}

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt lambda_bounds(# #)}}bounds for {it:lambda}; default {cmd:-.99 .99}{p_end}
{synopt:{opt ranktol(#)}}relative absorbed-column and numerical-rank tolerance; default {cmd:1e-7}{p_end}
{synopt:{opt optim_ptol(#)}}optimizer parameter tolerance; default {cmd:1e-14}{p_end}
{synopt:{opt optim_vtol(#)}}optimizer value tolerance; default {cmd:1e-13}{p_end}
{synopt:{opt maxiter(#)}}optimizer iteration cap; default {cmd:2000}{p_end}
{synoptline}

{pstd}
Retained covariates are standardized only inside the numerical calculation.
Reported coefficients, the covariance matrix, and predictions remain in the
variables' original units. Rank selection considers covariates in the supplied
order, retaining the first admissible column when a later column is numerically
dependent under {opt ranktol()}.

{title:Advanced diagnostics}

{pstd}
The following stored results support diagnostic and programmatic use. They are
not needed for ordinary estimation.

{synoptset 24 tabbed}{...}
{p2col 5 24 28 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations retained after iterative group/urn cleaning{p_end}
{synopt:{cmd:e(N_urns)}}number of urns{p_end}
{synopt:{cmd:e(N_groups)}}number of peer groups{p_end}
{synopt:{cmd:e(converged)}}1 if the final optimization converged, 0 otherwise{p_end}
{synopt:{cmd:e(criterion_s1)}}stage-one GMM criterion value{p_end}
{synopt:{cmd:e(criterion_s2)}}stage-two GMM criterion value{p_end}
{synopt:{cmd:e(lambda_lb)}}lower bound used for {it:lambda}{p_end}
{synopt:{cmd:e(lambda_ub)}}upper bound used for {it:lambda}{p_end}
{synopt:{cmd:e(rank_tol)}}relative numerical-rank tolerance used for the fit{p_end}
{synopt:{cmd:e(collinear_dropped)}}number of absorbed or numerically dependent covariates dropped{p_end}
{synopt:{cmd:e(inference_available)}}1 when covariance-based inference is available, 0 otherwise{p_end}

{p2col 5 24 28 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:peer_cra}{p_end}
{synopt:{cmd:e(optimizer_status)}}final optimizer status{p_end}
{synopt:{cmd:e(depvar)}}outcome variable name{p_end}
{synopt:{cmd:e(urn)}}urn variable name{p_end}
{synopt:{cmd:e(group)}}peer-group variable name{p_end}
{synopt:{cmd:e(own)}}own-effect covariate list{p_end}
{synopt:{cmd:e(peer)}}peer-effect covariate list{p_end}

{p2col 5 24 28 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient vector, beginning with {it:lambda}{p_end}
{synopt:{cmd:e(V)}}asymptotic covariance matrix; absent when inference is unavailable{p_end}
{synopt:{cmd:e(alpha)}}urn fixed effects, with one row per urn{p_end}
{synopt:{cmd:e(urn_info)}}urn-level diagnostics: urn identifier, observations, and peer groups{p_end}

{pstd}
Check {cmd:e(inference_available)} to determine whether covariance-based
inference is available. When it equals zero, point estimates remain available
but {cmd:e(V)} is not posted.

{title:Asymptotic regime}

{pstd}
Consistency and asymptotic normality require the average group size
{it:n/G} to remain bounded and the total number of groups {it:G} to grow.
Finite samples with few groups or large average groups may yield unreliable
estimates and standard errors. {cmd:peer_cra} warns only when the fitted result
shows an observable problem.

{title:References}

{pstd}
Ying Zeng. {it:Estimation and Inference for Peer Effects under Conditional
Random Assignment}. Manuscript.

{title:Also see}

{pstd}
Companion R package:
{browse "https://github.com/zengying17/peergmm-r":github.com/zengying17/peergmm-r}.
